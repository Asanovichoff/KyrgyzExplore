package com.kyrgyzexplore;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class KyrgyzexploreApplication {

	public static void main(String[] args) {
		SpringApplication.run(KyrgyzexploreApplication.class, args);
	}

}
