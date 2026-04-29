package com.kyrgyzexplore.listing;

import com.kyrgyzexplore.config.S3Config;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final S3Config s3Config;

    public String generatePresignedPutUrl(String s3Key) {
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(s3Config.getS3().getBucket())
                .key(s3Key)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .putObjectRequest(putRequest)
                .signatureDuration(Duration.ofMinutes(s3Config.getS3().getPresignDurationMinutes()))
                .build();

        return s3Presigner.presignPutObject(presignRequest).url().toString();
    }

    public void deleteObject(String s3Key) {
        s3Client.deleteObject(b -> b.bucket(s3Config.getS3().getBucket()).key(s3Key));
    }

    public String generatePresignedGetUrl(String s3Key) {
        GetObjectRequest getRequest = GetObjectRequest.builder()
                .bucket(s3Config.getS3().getBucket())
                .key(s3Key)
                .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .getObjectRequest(getRequest)
                .signatureDuration(Duration.ofMinutes(s3Config.getS3().getPresignDurationMinutes()))
                .build();

        return s3Presigner.presignGetObject(presignRequest).url().toString();
    }
}
