import "@typespec/http";
import "@typespec/openapi3";

using Http;

@service({
  title: "Booking API",
  version: "1.0.0"
})
@server("http://localhost:8000", "Local server")
namespace BookingApi;

/**
 * =========================
 * Schemas
 * =========================
 */

model EventType {
  id: string @format("uuid");
  name: string;
  description: string;
  duration_minutes: int32 @multipleOf(5) @minValue(5);
}

model Booking {
  id: string @format("uuid");
  event_type_id: string @format("uuid");
  start_at: utcDateTime;
  end_at: utcDateTime;
  guest_name: string;
  guest_email: string @format("email");
  status: "confirmed" | "cancelled";
  created_at: utcDateTime;
}

model Slot {
  /**
   * Only available (free) slots are returned.
   */
  start_at: utcDateTime;
  end_at: utcDateTime;
}

model PaginationMeta {
  current_page: int32 @minValue(1);
  per_page: int32 @minValue(1);
  total: int32 @minValue(0);
}

model ErrorDetailValidation {
  additionalProperties: string[];
}

model ErrorObject {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

model ErrorResponse {
  error: ErrorObject;
}

/**
 * =========================
 * Response Wrappers
 * =========================
 */

model SuccessResponse<T> {
  data: T;
}

model PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}

/**
 * =========================
 * Errors
 * =========================
 */

@error
model ValidationErrorResponse extends ErrorResponse {
  error: {
    code: "validation_error";
    message: "Validation failed";
    details: ErrorDetailValidation;
  };
}

@error
model ConflictErrorResponse extends ErrorResponse {
  error: {
    code: "conflict";
    message: string;
    details?: Record<string, unknown>;
  };
}

@error
model NotFoundErrorResponse extends ErrorResponse {
  error: {
    code: "not_found";
    message: string;
    details?: Record<string, unknown>;
  };
}

@error
model BadRequestErrorResponse extends ErrorResponse {
  error: {
    code: "bad_request";
    message: string;
    details?: Record<string, unknown>;
  };
}

/**
 * =========================
 * Event Types
 * =========================
 */

@route("/event-types")
interface EventTypesApi {
  @get
  list(): SuccessResponse<EventType[]>;

  @post
  create(@body body: EventTypeCreateRequest):
    | SuccessResponse<EventType>
    | ValidationErrorResponse
    | BadRequestErrorResponse;

  @patch("/{id}")
  update(
    @path id: string @format("uuid"),
    @body body: EventTypeUpdateRequest
  ):
    | SuccessResponse<EventType>
    | ValidationErrorResponse
    | NotFoundErrorResponse
    | BadRequestErrorResponse;
}

model EventTypeCreateRequest {
  name: string;
  description: string;
  duration_minutes: int32 @multipleOf(5) @minValue(5);
}

model EventTypeUpdateRequest {
  name?: string;
  description?: string;
  duration_minutes?: int32 @multipleOf(5) @minValue(5);
}

/**
 * =========================
 * Slots
 * =========================
 */

@route("/slots")
interface SlotsApi {
  @get
  list(
    @query event_type_id: string @format("uuid"),
    @query from: utcDateTime,
    @query to: utcDateTime
  ):
    | SuccessResponse<Slot[]>
    | ValidationErrorResponse
    | NotFoundErrorResponse
    | BadRequestErrorResponse;
}

/**
 * =========================
 * Bookings
 * =========================
 */

@route("/bookings")
interface BookingsApi {
  @post
  @statusCode(201)
  create(@body body: BookingCreateRequest):
    | SuccessResponse<Booking>
    | ValidationErrorResponse
    | ConflictErrorResponse
    | NotFoundErrorResponse
    | BadRequestErrorResponse;

  @get
  list(
    @query status?: "confirmed" | "cancelled",
    @query from?: utcDateTime,
    @query to?: utcDateTime,
    @query page?: int32 @minValue(1),
    @query per_page?: int32 @minValue(1) @maxValue(100)
  ):
    | PaginatedResponse<Booking>
    | ValidationErrorResponse
    | BadRequestErrorResponse;
}

@route("/bookings/{id}/cancel")
interface BookingCancelApi {
  @patch
  cancel(@path id: string @format("uuid")):
    | SuccessResponse<Booking>
    | NotFoundErrorResponse
    | BadRequestErrorResponse;
}

model BookingCreateRequest {
  /**
   * end_at is calculated automatically based on EventType duration
   */
  event_type_id: string @format("uuid");
  start_at: utcDateTime;
  guest_name: string;
  guest_email: string @format("email");
}