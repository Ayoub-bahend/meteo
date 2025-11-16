package com.meteo.location.service;

import com.meteo.location.model.Location;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@Service
public class LocationService {

    private final Map<String, Location> locationData = new HashMap<>();
    private final Random random = new Random();

    public LocationService() {
        // Initialize some sample location data
        locationData.put("Paris", new Location("Paris", "France", 48.8566, 2.3522, "Europe/Paris"));
        locationData.put("London", new Location("London", "United Kingdom", 51.5074, -0.1278, "Europe/London"));
        locationData.put("New York", new Location("New York", "United States", 40.7128, -74.0060, "America/New_York"));
        locationData.put("Tokyo", new Location("Tokyo", "Japan", 35.6762, 139.6503, "Asia/Tokyo"));
        locationData.put("Dubai", new Location("Dubai", "United Arab Emirates", 25.2048, 55.2708, "Asia/Dubai"));
    }

    public Location getLocationByCity(String city) {
        // If city exists, return it; otherwise generate random location
        String cityName = city.substring(0, 1).toUpperCase() + city.substring(1).toLowerCase();
        
        if (locationData.containsKey(cityName)) {
            return locationData.get(cityName);
        }
        
        // Generate random location for unknown cities  
        double lat = -90 + random.nextDouble() * 180;
        double lon = -180 + random.nextDouble() * 360;
        String country = "Unknown";
        String timezone = "UTC";
        
        Location location = new Location(cityName, country, 
            Math.round(lat * 10000.0) / 10000.0, 
            Math.round(lon * 10000.0) / 10000.0, 
            timezone);
        locationData.put(cityName, location);
        return location;
    }
}
