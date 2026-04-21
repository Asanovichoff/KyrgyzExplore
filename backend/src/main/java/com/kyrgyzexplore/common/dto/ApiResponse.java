package com.kyrgyzexplore.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;

/**
 * Every API response is wrapped in this envelope.
 *
 * WHY a consistent envelope?
 * The Flutter app always knows where to find the data and where to find errors.
 * Without this, every endpoint returns a different shape and the client has to
 * handle each one differently — which gets messy fast.
 *
 * Example success:  { "success": true,  "data": { ... }, "error": null }
 * Example error:    { "success": false, "data": null,    "error": "LISTING_NOT_FOUND" }
 */
@Getter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final boolean success;
    private final T data;
    private final String error;
    private final String message;

    private ApiResponse(boolean success, T data, String error, String message) {
        this.success = success;
        this.data = data;
        this.error = error;
        this.message = message;
    }

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null, null);
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, data, null, message);
    }

    public static <T> ApiResponse<T> error(String errorCode, String message) {
        return new ApiResponse<>(false, null, errorCode, message);
    }
}
