import ballerina/io;

// Public type definitions
public type Product record {
    string sku;
    string name;
    string description;
    float price;
    int stockQuantity;
    boolean available;
};

public type ProductResponse record {
    string message;
    Product? product;
};

public type ProductId record {
    string sku;
};

public type ProductListResponse record {
    Product[] products;
};

public type CartResponse record {
    string message;
};

public type AddToCartRequest record {
    string userId;
    string sku;
};

public type OrderResponse record {
    string message;
    Product[] products;
};

public type UserId record {
    string userId;
};

// Mock client implementation
public client class ShoppingServiceClient {
    private map<Product> productStore = {};
    private map<Product[]> userCarts = {};

    public function init(string url) {
        // In a real implementation, this would initialize a gRPC client
        io:println("Initialized mock ShoppingServiceClient with URL: " + url);
    }

    public function addProduct(Product product) returns ProductResponse {
        self.productStore[product.sku] = product;
        return {message: "Product added successfully", product: product};
    }

    public function listAvailableProducts() returns ProductListResponse {
        Product[] availableProducts = self.productStore.toArray().filter(p => p.available);
        return {products: availableProducts};
    }

    public function searchProduct(ProductId productId) returns ProductResponse {
        if (self.productStore.hasKey(productId.sku)) {
            return {message: "Product found", product: self.productStore.get(productId.sku)};
        }
        return {message: "Product not found", product: ()};
    }

    public function addToCart(AddToCartRequest request) returns CartResponse {
        if (!self.productStore.hasKey(request.sku)) {
            return {message: "Product not found"};
        }
        Product product = self.productStore.get(request.sku);
        if (!self.userCarts.hasKey(request.userId)) {
            self.userCarts[request.userId] = [];
        }
        self.userCarts.get(request.userId).push(product);
        return {message: "Product added to cart"};
    }

    public function placeOrder(UserId userId) returns OrderResponse {
        if (!self.userCarts.hasKey(userId.userId)) {
            return {message: "Cart is empty", products: []};
        }
        Product[] cart = self.userCarts.get(userId.userId);
        self.userCarts[userId.userId] = [];
        return {message: "Order placed successfully", products: cart};
    }
}

public function main() returns error? {
    // Initialize the mock client
    ShoppingServiceClient shoppingClient = new ("http://localhost:9090");

    // Example: Add a product
    Product newProduct = {
        sku: "PRD123",
        name: "Laptop",
        description: "High-performance laptop",
        price: 1200.50,
        stockQuantity: 10,
        available: true
    };
    ProductResponse productResponse = shoppingClient.addProduct(newProduct);
    io:println(productResponse.message);

    // Example: List available products
    ProductListResponse availableProducts = shoppingClient.listAvailableProducts();
    io:println("Available products:");
    foreach var product in availableProducts.products {
        io:println(product);
    }

    // Example: Search for a product
    ProductId productId = {sku: "PRD123"};
    ProductResponse searchResponse = shoppingClient.searchProduct(productId);
    io:println(searchResponse.message);

    // Example: Add product to cart and place order
    AddToCartRequest cartRequest = {userId: "cust001", sku: "PRD123"};
    CartResponse cartResponse = shoppingClient.addToCart(cartRequest);
    io:println(cartResponse.message);

    UserId userId = {userId: "cust001"};
    OrderResponse orderResponse = shoppingClient.placeOrder(userId);
    io:println(orderResponse.message);
}