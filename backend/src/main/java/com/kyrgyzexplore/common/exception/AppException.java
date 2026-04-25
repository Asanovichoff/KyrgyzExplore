package com.kyrgyzexplore.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Our custom exception. Throw this instead of generic RuntimeException
 * so the GlobalExceptionHandler can return the right HTTP status and error code.
 *
 * Usage: throw new AppException(HttpStatus.NOT_FOUND, "LISTING_NOT_FOUND", "Listing does not exist");
 */
@Getter
public class AppException extends RuntimeException {

    private final HttpStatus status;
    private final String errorCode;

    public AppException(HttpStatus status, String errorCode, String message) {
        super(message);
        this.status = status;
        this.errorCode = errorCode;
    }

    public static AppException notFound(String errorCode, String message) {
        return new AppException(HttpStatus.NOT_FOUND, errorCode, message);
    }

    public static AppException badRequest(String errorCode, String message) {
        return new AppException(HttpStatus.BAD_REQUEST, errorCode, message);
    }

    public static AppException forbidden(String errorCode, String message) {
        return new AppException(HttpStatus.FORBIDDEN, errorCode, message);
    }

    public static AppException internalServerError(String errorCode, String message) {
        return new AppException(HttpStatus.INTERNAL_SERVER_ERROR, errorCode, message);
    }
}
