package com.techie.microservices.order.config;

import io.swagger.v3.oas.models.ExternalDocumentation;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenAPIConfig {
    @Bean
    public OpenAPI orderServiceAPI(){
        return new OpenAPI()
                .info(new Info().title("Order Service")
                        .description("This is the REST API for Order Service")
                        .version("v0.0.1")
                        .license(new License().name("Apache 2.0")))
                .externalDocs(new ExternalDocumentation()
                        .description("You can refer to the Project documentation")
                        .url("https://correo2urledu-my.sharepoint.com/:w:/g/personal/eerivasa_correo_url_edu_gt/EbARm799M4xOo4DbKAFv4pABR3V4Lk6OwiXuJnIRus3b9w?e=HCB3vB"));
    }
}
