package com.meteo.location.controller;

import com.meteo.location.model.Location;
import com.meteo.location.service.LocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/location")
public class LocationController {

    @Autowired
    private LocationService locationService;

    @GetMapping("/{city}")
    public ResponseEntity<Location> getLocation(@PathVariable String city) {
        Location location = locationService.getLocationByCity(city);
        return ResponseEntity.ok(location);
    }
}
