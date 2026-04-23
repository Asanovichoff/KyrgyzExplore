package com.kyrgyzexplore.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

/**
 * Configures the AWS S3 client and pre-signer beans.
 *
 * WHY two separate beans (S3Client + S3Presigner)?
 * S3Client is used for regular operations (delete, copy).
 * S3Presigner is a separate utility specifically for generating pre-signed URLs —
 * it is not part of S3Client in SDK v2. They must be created and closed separately.
 *
 * WHY StaticCredentialsProvider?
 * For local dev we supply keys explicitly from .env. In production on AWS (EC2/ECS),
 * you'd switch to InstanceProfileCredentialsProvider and remove the keys entirely —
 * the instance's IAM role handles auth automatically, which is more secure.
 */
@Configuration
@ConfigurationProperties(prefix = "aws")
@Getter
@Setter
public class S3Config {

    private String accessKeyId;
    private String secretAccessKey;
    private String region;
    private S3Properties s3 = new S3Properties();

    @Getter
    @Setter
    public static class S3Properties {
        private String bucket;
        private int presignDurationMinutes;
    }

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKeyId, secretAccessKey)))
                .build();
    }

    @Bean
    public S3Presigner s3Presigner() {
        return S3Presigner.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKeyId, secretAccessKey)))
                .build();
    }
}
