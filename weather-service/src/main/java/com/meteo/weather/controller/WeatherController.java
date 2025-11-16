package com.meteo.weather.controller;

import com.meteo.weather.model.Weather;
import com.meteo.weather.service.WeatherService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/weather")
public class WeatherController {

    @Autowired
    private WeatherService weatherService;

    @GetMapping("/{city}")
    public ResponseEntity<Weather> getWeather(@PathVariable String city) {
        Weather weather = weatherService.getWeatherByCity(city);
        return ResponseEntity.ok(weather);
    }
}
