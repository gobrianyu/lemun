# Lemún

**App developed by Brian Yu, Rohan Shanthanu, Daniel Gao, Jacob Marcuson for CSE 340 class at University of Washington**


<p float="left">
  <img src="./lib/assets/mapview.jpg" alt="Screenshot of app's homepage" width="200"/>
  <img src="./lib/assets/compassview.jpg" alt="Screenshot of app's compass view" width="200"/> 
</p>

## Build steps
- Clone repository
- Run 'flutter pub get'
- Run the project using 'flutter run'
- Note: You will have to enable location permissions
- Once the app is ready, you can pan, zoom around the map, click on bikes, scooters, and bus stops to gain information about them, and use the legend to enable/disable vehicle types and move to your location

## Project structure:

### lib/assets/

- bus_stops.csv
- lemun_compass.png: image for the compass

### lib/helpers/

- scooter_checker.dart: Helper to update the list of scooters and bikes near the user

### lib/models/

- bus_stop_db.dart: a database of the bus stops, represented as a list of bus stops, created from the csv in the assets
- bus_stop.dart: represents a single bus stop, with its name and position 
- city.dart: enum with all the citiees in the Lime API
- drawing.dart: object to hold the draw actions of the user
- lime.dart: object to hold the data of Lime scooters and bikes
- link_scooter.dart: object to hold the data of Link scooters
- tools.dart: enum to determine what tool is being used on the canvas
- vehicle_types.dart: enum to determine what type of vehicle is being used (bus, scooter, bike)
- vehicle.dart: contains abstract class Vehicle to wrap around all vehicle types, has basic information of type, longitude, latitude

#### draw_actions/

- draw_actions.dart: Superclass to all draw actions

##### actions/

- clear_action.dart: Used to indicate the canvas was cleared
- null_action.dart: Used to indicate no stroke is being registered
- stroke_action.dart: Used to indicate user is drawing on the canvas

### lib/providers/

- drawing_provider.dart: Used to handle state of the drawing
- opacity_provider.dart: Used to handle state of the appbar
- position_provider.dart: Used to handle state of the user's position
- scooter_provider.dart: Used to handle state of the nearby scooters and bikes

### lib/views/

- city_selector.dart: Builds the drawer for selecting what city you are in
- compass_view.dart: contains CompassView class which requires a vehicle and displays a compass pointing from your current position to that vehicle. Also provides additional information about the vehicle such as availability and distance. 
- draw_area.dart: The canvas the user will see (although it is invisible)
- drawing_painter.dart: Displays the strokes the user took
- home_page.dart: Contains references to all the other views and logic for switching between them
- map_view.dart: contains MapView class, main view of the app displaying flutter_map and custom legend/filter
Clicking a marker on the map brings you to compass_view for that marker
- palette.dart: Builds the drawer for selecting colors for drawing

### lib/main.dart

- Builds the bus db and creates providers for all the data models, calling home_page and starting the app

## Data design and data flow
No user data is stored by this app. We use Lists to store the bikes, scooters, and bus stops with providers to update the data stored by those lists.

We created a provider that will periodically check with the scooter and bike APIs to make sure the vehicles nearby are up to date, which will update the Lists used to populate the map.

We created a provider to manage the state of the entire app, between being able to scroll through the map and being able to draw a path. This was done by toggling on and off a transparent version of the drawing app that we made, and changing what the drawer would contain (between colors and cities).

We used the same provider framework that was used in the drawing app to manage drawing state. We also used the same framework that was used in the food finder app to have a position provider that updates the users position and places them on the map.
