package com.meteo.weather.service;

import com.meteo.weather.model.Weather;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@Service
public class WeatherService {

    private final Map<String, Weather> weatherData = new HashMap<>();
    private final Random random = new Random();

    public WeatherService() {
        // Initialize some sample weather data
        weatherData.put("Paris", new Weather("Paris", 15.5, "Cloudy", "Partly cloudy with light breeze"));
        weatherData.put("London", new Weather("London", 12.0, "Rainy", "Light rain expected"));
        weatherData.put("New York", new Weather("New York", 20.0, "Sunny", "Clear skies and warm"));
        weatherData.put("Tokyo", new Weather("Tokyo", 18.0, "Cloudy", "Overcast conditions"));
        weatherData.put("Dubai", new Weather("Dubai", 32.0, "Sunny", "Hot and sunny"));
    }

    public Weather getWeatherByCity(String city) {
        // If city exists, return it; otherwise generate random weather
        String cityName = city.substring(0, 1).toUpperCase() + city.substring(1).toLowerCase();
        
        if (weatherData.containsKey(cityName)) {
            return weatherData.get(cityName);
        }
        
        // Generate random weather for unknown cities
        double temp = 10 + random.nextDouble() * 25;
        String[] conditions = {"Sunny", "Cloudy", "Rainy", "Partly Cloudy"};
        String condition = conditions[random.nextInt(conditions.length)];
        String description = "Weather conditions for " + cityName;
        
        Weather weather = new Weather(cityName, Math.round(temp * 10.0) / 10.0, condition, description);
        weatherData.put(cityName, weather);
        return weather;
    }
}
