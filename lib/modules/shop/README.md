PlayAround Shop module (integrated from EShopee patterns)

- Screens: shop_home_screen (listing + category/search), product_detail_screen, add_product_screen, cart_screen, orders_screen, checkout_screen
- Models: Product, Review, CartItem, OrderModel
- Services: ProductService, CartService, OrderService

Firestore structure (as required):
/products/{productId}
  - title, price, description, category, ownerId, images[], createdAt
/products/{productId}/reviews/{reviewId}
  - userId, rating, comment, timestamp
/users/{userId}/cart/{cartItemId}
  - productId, quantity
/orders/{orderId}
  - userId, items[], totalAmount, orderDate

