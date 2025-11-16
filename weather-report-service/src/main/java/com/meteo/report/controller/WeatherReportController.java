package com.meteo.report.controller;

import com.meteo.report.model.WeatherReport;
import com.meteo.report.service.WeatherReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/report")
public class WeatherReportController {

    @Autowired
    private WeatherReportService weatherReportService;

    @GetMapping("/{city}")
    public ResponseEntity<WeatherReport> getWeatherReport(@PathVariable String city) {
        WeatherReport report = weatherReportService.getWeatherReport(city);
        return ResponseEntity.ok(report);
    }
}
