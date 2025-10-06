# Venue Module

A comprehensive venue discovery, booking, and management system for the PlayAround sports app.

## Features

### 🏟️ Venue Discovery
- **Search & Filter**: Advanced search with filters for location, sport type, price range, amenities, and availability
- **Map View**: Interactive Google Maps integration showing nearby venues
- **List View**: Grid/list view with venue cards displaying key information
- **Real-time Availability**: Live booking slot availability

### 📋 Venue Profile
- **Detailed Information**: Complete venue details including amenities, pricing, and hours
- **Image Gallery**: High-quality venue photos with carousel view
- **Reviews & Ratings**: User reviews with verified booking badges
- **Coach Integration**: Links to available coaches at the venue

### 📅 Booking System
- **Slot Selection**: Calendar-based date and time selection
- **Duration Control**: Flexible booking duration (1-8 hours)
- **Participant Management**: Support for individual and group bookings
- **Payment Integration**: Secure payment processing with multiple payment methods
- **Confirmation Flow**: Email/SMS notifications and booking confirmations

### ⭐ Reviews & Ratings
- **User Reviews**: 5-star rating system with detailed feedback
- **Verified Reviews**: Only users who have booked can leave reviews
- **Review Categories**: Detailed rating breakdown by different aspects
- **Helpful Votes**: Community-driven review quality system

## File Structure

```
lib/screens/venue/
├── venue_discovery_screen.dart      # Main venue discovery with search/filters
├── venue_profile_screen.dart        # Detailed venue information page
├── venue_booking_screen.dart        # Booking flow and payment
└── widgets/
    ├── venue_card.dart              # Venue list item component
    ├── venue_filters_bottom_sheet.dart # Advanced filtering options
    ├── venue_map_view.dart          # Google Maps integration
    ├── venue_image_carousel.dart    # Image gallery component
    ├── venue_amenities_section.dart # Amenities display
    ├── venue_pricing_section.dart   # Pricing information
    ├── venue_reviews_section.dart   # Reviews and ratings
    ├── venue_booking_section.dart   # Quick booking widget
    ├── venue_hours_section.dart     # Operating hours display
    ├── booking_calendar.dart        # Date selection calendar
    ├── booking_time_slots.dart      # Time slot selection
    ├── booking_summary.dart         # Booking confirmation summary
    └── payment_integration.dart     # Payment processing
```

## Models

### Venue
- Complete venue information including location, amenities, pricing, and hours
- Support for multiple sports and high-quality images
- Verification status and owner information

### VenueBooking
- Booking details with start/end times, participants, and special requests
- Payment status and booking confirmation
- Cancellation and refund management

### VenueReview
- User reviews with ratings and detailed feedback
- Review categories and helpful voting system
- Verified booking integration

## Services

### VenueService
- CRUD operations for venues, bookings, and reviews
- Advanced search and filtering capabilities
- Real-time availability checking
- Analytics and reporting functions

## Integration

The venue module is integrated into the main navigation as the "Venues" tab, providing seamless access to venue discovery and booking functionality.

## Dependencies

- `google_maps_flutter`: Map integration
- `table_calendar`: Booking calendar
- `cached_network_image`: Image caching
- `url_launcher`: External links
- `flutter_stripe`: Payment processing
- `geolocator`: Location services

## Usage

1. **Discovery**: Users can search and filter venues by various criteria
2. **Profile**: Detailed venue information with images and reviews
3. **Booking**: Select date/time, duration, and participants
4. **Payment**: Secure payment processing with multiple options
5. **Confirmation**: Booking confirmation with email/SMS notifications

## Future Enhancements

- Virtual tours and AR integration
- Dynamic pricing based on demand
- Team/league booking options
- Loyalty points and discounts
- Tournament venue integration
- Real-time availability updates
- Advanced analytics dashboard
