import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// ============= Common Field Validators =============

// UUID validation
export const uuidSchema = z.string().uuid("Invalid UUID format");

// Optional UUID
export const optionalUuidSchema = z.string().uuid("Invalid UUID format").optional().nullable();

// Email validation
export const emailSchema = z.string().email("Invalid email format").max(255, "Email too long");

// Optional email
export const optionalEmailSchema = z.string().email("Invalid email format").max(255, "Email too long").optional().nullable();

// URL validation
export const urlSchema = z.string().url("Invalid URL format").max(2048, "URL too long");
export const optionalUrlSchema = z.string().url("Invalid URL format").max(2048, "URL too long").optional().nullable();

// Hex color validation
export const hexColorSchema = z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Invalid hex color format (e.g., #1a365d)");

// Phone validation
export const phoneSchema = z.string().regex(/^[\d\s()+-]{7,20}$/, "Invalid phone number format").optional().nullable();

// ============= String Length Constraints =============

// Short string (1-100 chars)
export const shortStringSchema = z.string().trim().min(1, "Field cannot be empty").max(100, "Maximum 100 characters");

// Medium string (1-500 chars)
export const mediumStringSchema = z.string().trim().min(1, "Field cannot be empty").max(500, "Maximum 500 characters");

// Long string (1-2000 chars)
export const longStringSchema = z.string().trim().min(1, "Field cannot be empty").max(2000, "Maximum 2000 characters");

// Optional variants
export const optionalShortStringSchema = z.string().trim().max(100, "Maximum 100 characters").optional().nullable();
export const optionalMediumStringSchema = z.string().trim().max(500, "Maximum 500 characters").optional().nullable();
export const optionalLongStringSchema = z.string().trim().max(2000, "Maximum 2000 characters").optional().nullable();

// ============= Common Enums =============

// App roles
export const appRoleSchema = z.enum(["admin", "organizer", "participant", "judge", "volunteer", "speaker"]);

// Workspace roles
export const workspaceRoleSchema = z.enum([
  "WORKSPACE_OWNER",
  "OPERATIONS_MANAGER",
  "GROWTH_MANAGER",
  "CONTENT_MANAGER",
  "TECH_FINANCE_MANAGER",
  "VOLUNTEERS_MANAGER",
  "EVENT_COORDINATOR",
  "VOLUNTEER_COORDINATOR",
  "MEMBER",
]);

// Notification types
export const notificationTypeSchema = z.enum([
  "broadcast",
  "task_assignment",
  "deadline_reminder",
  "channel_message",
]);

// Certificate types
export const certificateTypeSchema = z.enum([
  "Completion",
  "Achievement",
  "Participation",
  "Excellence",
  "Appreciation",
]);

// Design styles
export const designStyleSchema = z.enum([
  "elegant",
  "modern",
  "corporate",
  "creative",
  "academic",
]);

// Vendor status
export const vendorStatusSchema = z.enum([
  "VERIFIED",
  "REJECTED",
  "SUSPENDED",
]);

// Social platforms
export const socialPlatformSchema = z.enum([
  "twitter",
  "linkedin",
  "instagram",
]);

// ============= Helper Functions =============

/**
 * Creates a standardized validation error response
 */
export function validationError(
  error: z.ZodError,
  corsHeaders: Record<string, string>
): Response {
  const messages = error.errors
    .map((e) => (e.path.length > 0 ? `${e.path.join(".")}: ${e.message}` : e.message))
    .join(", ");

  console.log(`[VALIDATION_FAIL] ${messages}`);

  return new Response(JSON.stringify({ error: messages }), {
    status: 400,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Safely parses request body and validates against a schema
 */
export async function parseAndValidate<T extends z.ZodType>(
  req: Request,
  schema: T,
  corsHeaders: Record<string, string>
): Promise<{ success: true; data: z.infer<T> } | { success: false; response: Response }> {
  try {
    const rawBody = await req.json();
    const result = schema.safeParse(rawBody);

    if (!result.success) {
      return { success: false, response: validationError(result.error, corsHeaders) };
    }

    return { success: true, data: result.data };
  } catch {
    return {
      success: false,
      response: new Response(JSON.stringify({ error: "Invalid JSON body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }
}

// Re-export z for convenience
export { z };
