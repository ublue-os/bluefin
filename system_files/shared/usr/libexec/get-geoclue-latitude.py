#!/usr/bin/env python3

import time
import sys
from pydbus import SystemBus

LOCATION_TIMEOUT_SECONDS = 30
POLL_INTERVAL_SECONDS = 0.5

def get_geoclue_client():
    bus = SystemBus()
    manager = bus.get("org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager")
    client_path = manager.CreateClient()
    client = bus.get("org.freedesktop.GeoClue2", client_path)

    # Set client properties
    client.DesktopId = "bluefin-dynamic-wallpaper"
    # Request city-level accuracy (4) instead of country-level (1) to ensure
    # sufficiently precise latitude for reliable hemisphere detection.
    client.RequestedAccuracyLevel = 4
    client.Start()

    return bus, client

def wait_for_location(bus, client):
    """Wait for location data to become available."""
    max_attempts = int(LOCATION_TIMEOUT_SECONDS / POLL_INTERVAL_SECONDS)

    for attempt in range(max_attempts):
        try:
            if hasattr(client, 'Location') and client.Location:
                location_obj = bus.get("org.freedesktop.GeoClue2", client.Location)
                if (hasattr(location_obj, 'Latitude') and hasattr(location_obj, 'Longitude')):
                    latitude = location_obj.Latitude
                    longitude = location_obj.Longitude
                    # Treat (0.0, 0.0) as potentially uninitialized default coordinates.
                    if latitude is not None and longitude is not None and not (latitude == 0.0 and longitude == 0.0):
                        return latitude
        except Exception as e:
            # Ignore "object does not export any interfaces" errors during initialization
            if "object does not export any interfaces" not in str(e):
                print(f"error: unexpected error while waiting for location: {e}", file=sys.stderr)
                sys.exit(1)

        time.sleep(POLL_INTERVAL_SECONDS)

    # Timeout reached
    print("error: location unavailable after timeout", file=sys.stderr)
    sys.exit(1)

def main():
    try:
        bus, client = get_geoclue_client()
        latitude = wait_for_location(bus, client)
        print(latitude)
        sys.exit(0)

    except Exception as e:
        if "org.freedesktop.DBus.Error.AccessDenied" in str(e):
            print("error: location services disabled or denied", file=sys.stderr)
            sys.exit(2)
        else:
            print(f"error: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()
