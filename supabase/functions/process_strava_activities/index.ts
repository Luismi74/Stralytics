import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

/**
 * Rate limiter for Strava API.
 * Limits: 100 requests per 15 minutes, 1,000 per day.
 */
class StravaRateLimiter {
    private requests: number[] = [];
    private readonly FIFTEEN_MINUTES = 15 * 60 * 1000;
    private readonly MAX_REQUESTS_PER_15_MIN = 100;
    private readonly SAFETY_BUFFER = 10; // Leave buffer for safety

    async waitIfNeeded(): Promise<void> {
        const now = Date.now();

        // Clean up old requests
        this.requests = this.requests.filter(
            (timestamp) => now - timestamp < this.FIFTEEN_MINUTES
        );

        // Check if we're approaching the limit
        if (
            this.requests.length >=
            this.MAX_REQUESTS_PER_15_MIN - this.SAFETY_BUFFER
        ) {
            const oldestRequest = this.requests[0];
            const waitTime = this.FIFTEEN_MINUTES - (now - oldestRequest);

            if (waitTime > 0) {
                console.log(`Rate limit approaching. Waiting ${waitTime}ms...`);
                await new Promise((resolve) => setTimeout(resolve, waitTime));
            }

            // Clean up again after waiting
            const newNow = Date.now();
            this.requests = this.requests.filter(
                (timestamp) => newNow - timestamp < this.FIFTEEN_MINUTES
            );
        }

        // Record this request
        this.requests.push(now);
    }
}

interface RequestBody {
    jobId: string;
    accessToken: string;
}

/**
 * Fetches activities from Strava API.
 */
async function fetchActivities(
    accessToken: string,
    rateLimiter: StravaRateLimiter
): Promise<any[]> {
    await rateLimiter.waitIfNeeded();

    const response = await fetch(
        "https://www.strava.com/api/v3/athlete/activities?per_page=200",
        {
            headers: { Authorization: `Bearer ${accessToken}` },
        }
    );

    if (!response.ok) {
        throw new Error(`Failed to fetch activities: ${response.statusText}`);
    }

    return await response.json();
}

/**
 * Fetches detailed activity data including segment efforts.
 */
async function fetchActivityDetail(
    activityId: number,
    accessToken: string,
    rateLimiter: StravaRateLimiter
): Promise<any> {
    await rateLimiter.waitIfNeeded();

    const response = await fetch(
        `https://www.strava.com/api/v3/activities/${activityId}`,
        {
            headers: { Authorization: `Bearer ${accessToken}` },
        }
    );

    if (!response.ok) {
        throw new Error(
            `Failed to fetch activity ${activityId}: ${response.statusText}`
        );
    }

    return await response.json();
}

/**
 * Fetches activity streams (latlng, heartrate, watts, etc.).
 */
async function fetchActivityStreams(
    activityId: number,
    accessToken: string,
    rateLimiter: StravaRateLimiter
): Promise<any> {
    await rateLimiter.waitIfNeeded();

    const streamTypes = [
        "time",
        "latlng",
        "distance",
        "altitude",
        "heartrate",
        "watts",
        "cadence",
        "temp",
    ];

    const response = await fetch(
        `https://www.strava.com/api/v3/activities/${activityId}/streams?keys=${streamTypes.join(
            ","
        )}&key_by_type=true`,
        {
            headers: { Authorization: `Bearer ${accessToken}` },
        }
    );

    if (!response.ok) {
        // It's okay if streams don't exist
        if (response.status === 404) return {};
        throw new Error(
            `Failed to fetch streams for ${activityId}: ${response.statusText}`
        );
    }

    return await response.json();
}

/**
 * Downloads an image and uploads it to Supabase Storage.
 */
async function downloadAndStoreImage(
    imageUrl: string,
    activityId: number,
    userId: string,
    supabase: any
): Promise<string | null> {
    try {
        // Download image
        const response = await fetch(imageUrl);
        if (!response.ok) return null;

        const blob = await response.blob();
        const extension = imageUrl.split(".").pop()?.split("?")[0] || "jpg";
        const filename = `${userId}/${activityId}_${Date.now()}.${extension}`;

        // Upload to Supabase Storage
        const { data, error } = await supabase.storage
            .from("activity-images")
            .upload(filename, blob, {
                contentType: blob.type,
                upsert: false,
            });

        if (error) {
            console.error(`Failed to upload image: ${error.message}`);
            return null;
        }

        // Get public URL
        const {
            data: { publicUrl },
        } = supabase.storage.from("activity-images").getPublicUrl(filename);

        return publicUrl;
    } catch (error) {
        console.error(`Error downloading/storing image: ${error}`);
        return null;
    }
}

/**
 * Updates job status and progress in the database.
 */
async function updateJob(
    supabase: any,
    jobId: string,
    updates: Record<string, any>
) {
    const { error } = await supabase
        .from("processing_jobs")
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq("id", jobId);

    if (error) {
        console.error(`Failed to update job: ${error.message}`);
    }
}

/**
 * Main Edge Function handler.
 */
serve(async (req) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { jobId, accessToken }: RequestBody = await req.json();

        // Initialize Supabase admin client
        const supabaseUrl = Deno.env.get("PROJECT_URL")!;
        const supabaseServiceKey = Deno.env.get("SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Get job details
        const { data: job, error: jobError } = await supabase
            .from("processing_jobs")
            .select("user_id")
            .eq("id", jobId)
            .single();

        if (jobError || !job) {
            throw new Error("Job not found");
        }

        const userId = job.user_id;
        const rateLimiter = new StravaRateLimiter();

        // Update status to processing
        await updateJob(supabase, jobId, { status: "processing" });

        // Fetch activities list
        console.log("Fetching activities list...");
        const activities = await fetchActivities(accessToken, rateLimiter);

        await updateJob(supabase, jobId, {
            total_activities: activities.length,
        });

        console.log(`Processing ${activities.length} activities...`);

        let processedCount = 0;

        // Process each activity
        for (const activity of activities) {
            try {
                // Check if job was cancelled
                const { data: currentJob } = await supabase
                    .from("processing_jobs")
                    .select("status")
                    .eq("id", jobId)
                    .single();

                if (currentJob?.status === "cancelled") {
                    console.log("Job cancelled by user");
                    return new Response(
                        JSON.stringify({ success: false, message: "Job cancelled" }),
                        {
                            headers: { ...corsHeaders, "Content-Type": "application/json" },
                        }
                    );
                }

                // Update current activity
                await updateJob(supabase, jobId, {
                    current_activity_name: activity.name,
                });

                // Check if activity already exists (skip if so)
                const { data: existingActivity } = await supabase
                    .from("activities")
                    .select("activity_id")
                    .eq("activity_id", activity.id)
                    .maybeSingle();

                if (existingActivity) {
                    console.log(`Skipping activity ${activity.id} (${activity.name}) - already exists.`);
                    processedCount++;
                    await updateJob(supabase, jobId, {
                        processed_activities: processedCount,
                    });
                    continue;
                }

                // Fetch detailed activity data
                const detail = await fetchActivityDetail(
                    activity.id,
                    accessToken,
                    rateLimiter
                );

                // Fetch streams
                const streams = await fetchActivityStreams(
                    activity.id,
                    accessToken,
                    rateLimiter
                );

                // Download images if available
                const imageUrls: string[] = [];
                if (activity.photos?.primary?.urls?.["600"]) {
                    const url = await downloadAndStoreImage(
                        activity.photos.primary.urls["600"],
                        activity.id,
                        userId,
                        supabase
                    );
                    if (url) imageUrls.push(url);
                }

                // Store activity
                const { error: activityError } = await supabase
                    .from("activities")
                    .upsert({
                        activity_id: activity.id,
                        user_id: userId,
                        name: activity.name,
                        start_date: activity.start_date,
                        distance: activity.distance,
                        moving_time: activity.moving_time,
                        elapsed_time: activity.elapsed_time,
                        total_elevation_gain: activity.total_elevation_gain,
                        sport_type: activity.sport_type || activity.type,
                        raw_data: detail,
                        image_urls: imageUrls,
                    });

                if (activityError) {
                    console.error(
                        `Failed to store activity ${activity.id}: ${activityError.message}`
                    );
                }

                // Store streams
                for (const [streamType, streamData] of Object.entries(streams)) {
                    if (streamData && typeof streamData === "object") {
                        const { error: streamError } = await supabase
                            .from("activity_streams")
                            .upsert({
                                activity_id: activity.id,
                                stream_type: streamType,
                                data: (streamData as any).data || [],
                            });

                        if (streamError) {
                            console.error(
                                `Failed to store stream ${streamType}: ${streamError.message}`
                            );
                        }
                    }
                }

                processedCount++;

                // Update progress
                await updateJob(supabase, jobId, {
                    processed_activities: processedCount,
                });

                console.log(
                    `Processed ${processedCount}/${activities.length}: ${activity.name}`
                );
            } catch (error) {
                console.error(`Error processing activity ${activity.id}:`, error);
                // Continue with next activity
            }
        }

        // Mark job as completed
        await updateJob(supabase, jobId, {
            status: "completed",
            completed_at: new Date().toISOString(),
            current_activity_name: null,
        });

        console.log(`Processing completed! Processed ${processedCount} activities.`);

        return new Response(
            JSON.stringify({ success: true, processedCount }),
            {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    } catch (error) {
        console.error("Edge Function error:", error);

        // Try to update job status to failed
        try {
            const { jobId } = await req.json();
            const supabaseUrl = Deno.env.get("PROJECT_URL")!;
            const supabaseServiceKey = Deno.env.get("SERVICE_ROLE_KEY")!;
            const supabase = createClient(supabaseUrl, supabaseServiceKey);

            await updateJob(supabase, jobId, {
                status: "failed",
                error_message: error.message,
            });
        } catch (updateError) {
            console.error("Failed to update job status:", updateError);
        }

        return new Response(
            JSON.stringify({ success: false, error: error.message }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    }
});
