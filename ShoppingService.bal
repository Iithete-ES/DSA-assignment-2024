 import ballerina/grpc;
import ballerina/log;

type Product record {
    string sku;
    string name;
    string description;
    float price;
    int stockQuantity;
    boolean available;
};

type User record {
    string userId;
    string name;
    string userType; // Either 'admin' or 'customer'
};

type ProductResponse record {
    string message;
    Product? product;
};

type ProductId record {
    string sku;
};

type ProductListResponse record {
    Product[] products;
};

type CartResponse record {
    string message;
};

type AddToCartRequest record {
    string userId;
    string sku;
};

type OrderResponse record {
    string message;
    Product[] products;
};

type UserId record {
    string userId;
};

type UserCreationResponse record {
    string message;
};

map<Product> productStore = {};
map<Product[]> userCarts = {};
map<User> userStore = {};

service "ShoppingService" on new grpc:Listener(9090) {

    remote function addProduct(Product product) returns ProductResponse {
        productStore[product.sku] = product;
        return {message: "Product added successfully", product: product};
    }

    remote function updateProduct(Product product) returns ProductResponse {
        if productStore.hasKey(product.sku) {
            productStore[product.sku] = product;
            return {message: "Product updated successfully", product: product};
        }
        return {message: "Product not found", product: ()};
    }

    remote function removeProduct(ProductId productId) returns ProductListResponse {
        _ = productStore.remove(productId.sku);
        return listAllProducts();
    }

    remote function listAvailableProducts() returns ProductListResponse {
        Product[] availableProducts = productStore.toArray().filter(product => product.available);
        return {products: availableProducts};
    }

    remote function searchProduct(ProductId productId) returns ProductResponse {
        if productStore.hasKey(productId.sku) {
            return {message: "Product found", product: productStore.get(productId.sku)};
        } else {
            return {message: "Product not found", product: ()};
        }
    }

    remote function addToCart(AddToCartRequest request) returns CartResponse {
        if !productStore.hasKey(request.sku) {
            return {message: "Product not found"};
        }
        Product product = productStore.get(request.sku);
        if product.available {
            if !userCarts.hasKey(request.userId) {
                userCarts[request.userId] = [];
            }
            userCarts.get(request.userId).push(product);
            return {message: "Product added to cart"};
        } else {
            return {message: "Product is not available"};
        }
    }

    remote function placeOrder(UserId userId) returns OrderResponse {
        if !userCarts.hasKey(userId.userId) {
            return {message: "Cart is empty", products: []};
        }
        Product[] cart = userCarts.get(userId.userId);
        if cart.length() > 0 {
            _ = userCarts.remove(userId.userId); // Clear the cart
            return {message: "Order placed successfully", products: cart};
        } else {
            return {message: "Cart is empty", products: []};
        }
    }

    remote function createUsers(stream<User, error?> users) returns UserCreationResponse|error {
        check users.forEach(function(User user) {
            userStore[user.userId] = user;
            log:printInfo("User created: " + user.userId);
        });
        return {message: "Users created successfully"};
    }

    // Helper function to list all products
    function listAllProducts() returns ProductListResponse {
        return {products: productStore.toArray()};
    }
}
