package com.meteo.report.service;

import com.meteo.report.model.Location;
import com.meteo.report.model.Weather;
import com.meteo.report.model.WeatherReport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
public class WeatherReportService {

    @Autowired
    private RestTemplate restTemplate;

    @Value("${weather.service.url:http://localhost:8081}")
    private String weatherServiceUrl;

    @Value("${location.service.url:http://localhost:8082}")
    private String locationServiceUrl;

    public WeatherReport getWeatherReport(String city) {
        // Call Weather Service
        Weather weather = restTemplate.getForObject(
            weatherServiceUrl + "/api/weather/" + city, 
            Weather.class
        );

        // Call Location Service
        Location location = restTemplate.getForObject(
            locationServiceUrl + "/api/location/" + city, 
            Location.class
        );

        // Combine data into a comprehensive weather report
        WeatherReport report = new WeatherReport();
        if (weather != null) {
            report.setCity(weather.getCity());
            report.setTemperature(weather.getTemperature());
            report.setCondition(weather.getCondition());
            report.setDescription(weather.getDescription());
        }

        if (location != null) {
            report.setCity(location.getCity());
            report.setCountry(location.getCountry());
            report.setLatitude(location.getLatitude());
            report.setLongitude(location.getLongitude());
            report.setTimezone(location.getTimezone());
        }

        // Add report generation date
        report.setReportDate(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));

        return report;
    }
}
