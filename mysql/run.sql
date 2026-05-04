-- Restaurant Ordering System: full rebuild
-- Drops the existing database, recreates the schema, and loads sample data.

DROP DATABASE IF EXISTS RestaurantOrderingSystemDB;

-- Restaurant Ordering System Schema

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema RestaurantOrderingSystemDB
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `RestaurantOrderingSystemDB` DEFAULT CHARACTER SET utf8mb4;
USE `RestaurantOrderingSystemDB`;

-- -----------------------------------------------------
-- Table `Customer`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Customer` (
  `customer_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `phone_number` VARCHAR(20) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`customer_id`),
  UNIQUE INDEX `UQ_customer_email` (`email`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Restaurant`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Restaurant` (
  `restaurant_id` INT NOT NULL AUTO_INCREMENT,
  `restaurant_name` VARCHAR(100) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `phone_number` VARCHAR(20) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`restaurant_id`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `RestaurantHours` (one row per restaurant per day_of_week)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `RestaurantHours` (
  `restaurant_id` INT NOT NULL,
  `day_of_week` TINYINT NOT NULL,
  `open_time` TIME NOT NULL,
  `close_time` TIME NOT NULL,
  PRIMARY KEY (`restaurant_id`, `day_of_week`),
  CONSTRAINT `CK_hours_day` CHECK (`day_of_week` BETWEEN 0 AND 6),
  CONSTRAINT `CK_hours_range` CHECK (`open_time` < `close_time`),
  CONSTRAINT `FK_hours_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Employee`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Employee` (
  `employee_id` INT NOT NULL AUTO_INCREMENT,
  `restaurant_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `phone_number` VARCHAR(20) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `position` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`employee_id`),
  UNIQUE INDEX `UQ_employee_email` (`email`),
  INDEX `FK_employee_restaurant_idx` (`restaurant_id`),
  CONSTRAINT `FK_employee_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Orders`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Orders` (
  `order_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `restaurant_id` INT NOT NULL,
  `order_date` DATE NOT NULL,
  `total_amount` DECIMAL(10,2) NOT NULL,
  `status` ENUM('pending','preparing','ready','delivered','cancelled') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`),
  INDEX `FK_order_customer_idx` (`customer_id`),
  INDEX `FK_order_restaurant_idx` (`restaurant_id`),
  INDEX `IX_order_date` (`order_date`),
  CONSTRAINT `FK_order_customer`
    FOREIGN KEY (`customer_id`) REFERENCES `Customer` (`customer_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `FK_order_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Payment`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Payment` (
  `payment_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `payment_type` ENUM('Cash','Credit Card','Debit Card','Mobile Pay') NOT NULL,
  `payment_date` DATE NOT NULL,
  PRIMARY KEY (`payment_id`),
  INDEX `FK_payment_order_idx` (`order_id`),
  CONSTRAINT `FK_payment_order`
    FOREIGN KEY (`order_id`) REFERENCES `Orders` (`order_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Delivery`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Delivery` (
  `delivery_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `employee_id` INT NOT NULL,
  `scheduled_time` DATETIME NOT NULL,
  `actual_delivery_time` DATETIME NULL,
  `delivery_address` VARCHAR(255) NOT NULL,
  `status` ENUM('scheduled','out_for_delivery','delivered','failed') NOT NULL DEFAULT 'scheduled',
  PRIMARY KEY (`delivery_id`),
  INDEX `FK_delivery_order_idx` (`order_id`),
  INDEX `FK_delivery_employee_idx` (`employee_id`),
  CONSTRAINT `FK_delivery_order`
    FOREIGN KEY (`order_id`) REFERENCES `Orders` (`order_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_delivery_employee`
    FOREIGN KEY (`employee_id`) REFERENCES `Employee` (`employee_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Menu`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Menu` (
  `menu_id` INT NOT NULL AUTO_INCREMENT,
  `restaurant_id` INT NOT NULL,
  `menu_type` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`menu_id`),
  INDEX `FK_menu_restaurant_idx` (`restaurant_id`),
  CONSTRAINT `FK_menu_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Category`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Category` (
  `category_id` INT NOT NULL AUTO_INCREMENT,
  `menu_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`category_id`),
  INDEX `FK_category_menu_idx` (`menu_id`),
  CONSTRAINT `FK_category_menu`
    FOREIGN KEY (`menu_id`) REFERENCES `Menu` (`menu_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `MenuItem`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MenuItem` (
  `menu_item_id` INT NOT NULL AUTO_INCREMENT,
  `menu_id` INT NOT NULL,
  `category_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `is_available` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`menu_item_id`),
  INDEX `FK_menu_item_menu_idx` (`menu_id`),
  INDEX `FK_menu_item_category_idx` (`category_id`),
  CONSTRAINT `CK_menu_item_price` CHECK (`price` >= 0),
  CONSTRAINT `FK_menu_item_menu`
    FOREIGN KEY (`menu_id`) REFERENCES `Menu` (`menu_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_menu_item_category`
    FOREIGN KEY (`category_id`) REFERENCES `Category` (`category_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `OrderItem`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OrderItem` (
  `order_item_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `menu_item_id` INT NOT NULL,
  `quantity` INT NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`order_item_id`),
  INDEX `FK_order_item_order_idx` (`order_id`),
  INDEX `FK_order_item_menu_item_idx` (`menu_item_id`),
  CONSTRAINT `CK_order_item_quantity` CHECK (`quantity` > 0),
  CONSTRAINT `FK_order_item_order`
    FOREIGN KEY (`order_id`) REFERENCES `Orders` (`order_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_order_item_menu_item`
    FOREIGN KEY (`menu_item_id`) REFERENCES `MenuItem` (`menu_item_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Tables`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Tables` (
  `table_id` INT NOT NULL AUTO_INCREMENT,
  `restaurant_id` INT NOT NULL,
  `capacity` INT NOT NULL,
  `status` ENUM('Available','Reserved','Occupied','OutOfService') NOT NULL DEFAULT 'Available',
  PRIMARY KEY (`table_id`),
  INDEX `FK_table_restaurant_idx` (`restaurant_id`),
  CONSTRAINT `CK_table_capacity` CHECK (`capacity` > 0),
  CONSTRAINT `FK_table_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Reservation`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Reservation` (
  `reservation_id` INT NOT NULL AUTO_INCREMENT,
  `table_id` INT NOT NULL,
  `customer_id` INT NOT NULL,
  `restaurant_id` INT NOT NULL,
  `reservation_date_time` DATETIME NOT NULL,
  `party_size` INT NOT NULL,
  `duration_minutes` INT NOT NULL DEFAULT 90,
  `status` ENUM('booked','seated','completed','cancelled','no_show') NOT NULL DEFAULT 'booked',
  PRIMARY KEY (`reservation_id`),
  INDEX `FK_reservation_table_idx` (`table_id`),
  INDEX `FK_reservation_customer_idx` (`customer_id`),
  INDEX `FK_reservation_restaurant_idx` (`restaurant_id`),
  INDEX `IX_reservation_datetime` (`reservation_date_time`),
  CONSTRAINT `CK_reservation_party_size` CHECK (`party_size` > 0),
  CONSTRAINT `CK_reservation_duration` CHECK (`duration_minutes` > 0),
  CONSTRAINT `FK_reservation_table`
    FOREIGN KEY (`table_id`) REFERENCES `Tables` (`table_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `FK_reservation_customer`
    FOREIGN KEY (`customer_id`) REFERENCES `Customer` (`customer_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_reservation_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Supplier`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Supplier` (
  `supplier_id` INT NOT NULL AUTO_INCREMENT,
  `restaurant_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `phone_number` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`supplier_id`),
  INDEX `FK_supplier_restaurant_idx` (`restaurant_id`),
  CONSTRAINT `FK_supplier_restaurant`
    FOREIGN KEY (`restaurant_id`) REFERENCES `Restaurant` (`restaurant_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Ingredient` (master list, deduplicated)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Ingredient` (
  `ingredient_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `unit` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`ingredient_id`),
  UNIQUE INDEX `UQ_ingredient_name` (`name`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `MenuItemIngredient` (recipe junction)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MenuItemIngredient` (
  `menu_item_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  `quantity` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`menu_item_id`, `ingredient_id`),
  INDEX `FK_mii_ingredient_idx` (`ingredient_id`),
  CONSTRAINT `CK_mii_quantity` CHECK (`quantity` > 0),
  CONSTRAINT `FK_mii_menu_item`
    FOREIGN KEY (`menu_item_id`) REFERENCES `MenuItem` (`menu_item_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mii_ingredient`
    FOREIGN KEY (`ingredient_id`) REFERENCES `Ingredient` (`ingredient_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `SupplierIngredient` (who supplies what)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SupplierIngredient` (
  `supplier_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  `price_per_unit` DECIMAL(10,2) NULL,
  PRIMARY KEY (`supplier_id`, `ingredient_id`),
  INDEX `FK_si_ingredient_idx` (`ingredient_id`),
  CONSTRAINT `FK_si_supplier`
    FOREIGN KEY (`supplier_id`) REFERENCES `Supplier` (`supplier_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_si_ingredient`
    FOREIGN KEY (`ingredient_id`) REFERENCES `Ingredient` (`ingredient_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Shift`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Shift` (
  `shift_id` INT NOT NULL AUTO_INCREMENT,
  `employee_id` INT NOT NULL,
  `start_time` DATETIME NOT NULL,
  `end_time` DATETIME NOT NULL,
  PRIMARY KEY (`shift_id`),
  INDEX `FK_shift_employee_idx` (`employee_id`),
  INDEX `IX_shift_start_time` (`start_time`),
  CONSTRAINT `CK_shift_range` CHECK (`start_time` < `end_time`),
  CONSTRAINT `FK_shift_employee`
    FOREIGN KEY (`employee_id`) REFERENCES `Employee` (`employee_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Feedback`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Feedback` (
  `feedback_id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `customer_id` INT NOT NULL,
  `rating` TINYINT NOT NULL,
  `comment` VARCHAR(500) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedback_id`),
  INDEX `FK_feedback_customer_idx` (`customer_id`),
  INDEX `FK_feedback_order_idx` (`order_id`),
  CONSTRAINT `FK_feedback_order`
    FOREIGN KEY (`order_id`) REFERENCES `Orders` (`order_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_feedback_customer`
    FOREIGN KEY (`customer_id`) REFERENCES `Customer` (`customer_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `CK_feedback_rating` CHECK (`rating` BETWEEN 1 AND 5)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Promotions`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Promotions` (
  `promotion_id` INT NOT NULL AUTO_INCREMENT,
  `menu_item_id` INT NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `discount_type` ENUM('PERCENTAGE','FIXED') NOT NULL,
  `discount_value` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`promotion_id`),
  INDEX `FK_promotion_menu_item_idx` (`menu_item_id`),
  CONSTRAINT `CK_promotion_dates` CHECK (`start_date` <= `end_date`),
  CONSTRAINT `CK_promotion_value` CHECK (`discount_value` >= 0),
  CONSTRAINT `FK_promotion_menu_item`
    FOREIGN KEY (`menu_item_id`) REFERENCES `MenuItem` (`menu_item_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `LoyaltyProgram` (enrollment record only — points live in LoyaltyTransaction)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LoyaltyProgram` (
  `loyalty_program_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `joined_date` DATE NOT NULL,
  PRIMARY KEY (`loyalty_program_id`),
  UNIQUE INDEX `UQ_loyalty_customer` (`customer_id`),
  CONSTRAINT `FK_loyalty_program_customer`
    FOREIGN KEY (`customer_id`) REFERENCES `Customer` (`customer_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `LoyaltyTransaction` (point ledger; sum gives current balance)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LoyaltyTransaction` (
  `transaction_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `order_id` INT NULL,
  `points_delta` INT NOT NULL,
  `reason` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`transaction_id`),
  INDEX `FK_loyalty_txn_customer_idx` (`customer_id`),
  INDEX `FK_loyalty_txn_order_idx` (`order_id`),
  CONSTRAINT `FK_loyalty_txn_customer`
    FOREIGN KEY (`customer_id`) REFERENCES `Customer` (`customer_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_loyalty_txn_order`
    FOREIGN KEY (`order_id`) REFERENCES `Orders` (`order_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Invoice` (one per payment; totals derive from Payment -> Orders)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Invoice` (
  `invoice_id` INT NOT NULL AUTO_INCREMENT,
  `payment_id` INT NOT NULL,
  `issue_date` DATE NOT NULL,
  PRIMARY KEY (`invoice_id`),
  UNIQUE INDEX `UQ_invoice_payment` (`payment_id`),
  CONSTRAINT `FK_invoice_payment`
    FOREIGN KEY (`payment_id`) REFERENCES `Payment` (`payment_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

USE RestaurantOrderingSystemDB;

-- Insert into Restaurant table
INSERT IGNORE INTO Restaurant (restaurant_id, restaurant_name, address, phone_number)
VALUES
(1, 'The Italian Bistro', '123 Main St, City', '555-0001'),
(2, 'Sushi Delight', '456 Oak St, Town', '555-0002'),
(3, 'Burger Heaven', '789 Pine St, Village', '555-0003'),
(4, 'Taco Fiesta', '321 Elm St, City', '555-0004'),
(5, 'Spice Garden', '654 Maple Ave, Town', '555-0005'),
(6, 'Green Leaf', '987 Cedar Rd, Village', '555-0006');

-- Insert into RestaurantHours (day_of_week: 0=Sun ... 6=Sat)
INSERT IGNORE INTO RestaurantHours (restaurant_id, day_of_week, open_time, close_time)
VALUES
(1, 0, '09:00:00', '21:00:00'), (1, 1, '09:00:00', '21:00:00'), (1, 2, '09:00:00', '21:00:00'),
(1, 3, '09:00:00', '21:00:00'), (1, 4, '09:00:00', '21:00:00'), (1, 5, '09:00:00', '21:00:00'),
(1, 6, '09:00:00', '21:00:00'),
(2, 0, '10:00:00', '22:00:00'), (2, 1, '10:00:00', '22:00:00'), (2, 2, '10:00:00', '22:00:00'),
(2, 3, '10:00:00', '22:00:00'), (2, 4, '10:00:00', '22:00:00'), (2, 5, '10:00:00', '22:00:00'),
(2, 6, '10:00:00', '22:00:00'),
(3, 0, '08:00:00', '20:00:00'), (3, 1, '08:00:00', '20:00:00'), (3, 2, '08:00:00', '20:00:00'),
(3, 3, '08:00:00', '20:00:00'), (3, 4, '08:00:00', '20:00:00'), (3, 5, '08:00:00', '20:00:00'),
(3, 6, '08:00:00', '20:00:00'),
(4, 0, '11:00:00', '23:00:00'), (4, 1, '11:00:00', '23:00:00'), (4, 2, '11:00:00', '23:00:00'),
(4, 3, '11:00:00', '23:00:00'), (4, 4, '11:00:00', '23:00:00'), (4, 5, '11:00:00', '23:00:00'),
(4, 6, '11:00:00', '23:00:00'),
(5, 0, '12:00:00', '22:00:00'), (5, 1, '12:00:00', '22:00:00'), (5, 2, '12:00:00', '22:00:00'),
(5, 3, '12:00:00', '22:00:00'), (5, 4, '12:00:00', '22:00:00'), (5, 5, '12:00:00', '22:00:00'),
(5, 6, '12:00:00', '22:00:00'),
(6, 0, '07:00:00', '21:00:00'), (6, 1, '07:00:00', '21:00:00'), (6, 2, '07:00:00', '21:00:00'),
(6, 3, '07:00:00', '21:00:00'), (6, 4, '07:00:00', '21:00:00'), (6, 5, '07:00:00', '21:00:00'),
(6, 6, '07:00:00', '21:00:00');

-- Insert into Menu table
INSERT IGNORE INTO Menu (menu_id, restaurant_id, menu_type)
VALUES
(1, 1, 'Regular'),
(2, 1, 'Special'),
(3, 2, 'Regular'),
(4, 2, 'Lunch'),
(5, 3, 'Regular'),
(6, 3, 'Kids'),
(7, 4, 'Regular'),
(8, 4, 'Late Night'),
(9, 5, 'Regular'),
(10, 5, 'Vegetarian'),
(11, 6, 'Regular'),
(12, 6, 'Smoothie');

-- Insert into Category table
INSERT IGNORE INTO Category (category_id, menu_id, name, description)
VALUES
(1, 1, 'Appetizers', 'Small dishes to start a meal'),
(2, 1, 'Pastas', 'Italian pasta dishes'),
(3, 1, 'Desserts', 'Sweet dishes to end a meal'),
(4, 2, 'Main Course', 'Hearty and filling dishes'),
(5, 3, 'Sushi Rolls', 'Classic and specialty rolls'),
(6, 3, 'Sashimi', 'Fresh sliced fish'),
(7, 4, 'Bento Boxes', 'Complete lunch sets'),
(8, 5, 'Burgers', 'Signature burgers'),
(9, 5, 'Sides', 'Perfect burger companions'),
(10, 6, 'Kids Meals', 'Child-friendly portions'),
(11, 7, 'Tacos', 'Traditional and modern tacos'),
(12, 7, 'Burritos', 'Filled and rolled wraps'),
(13, 8, 'Nachos', 'Loaded nacho platters'),
(14, 9, 'Curries', 'Spiced dishes with rice'),
(15, 9, 'Breads', 'Fresh baked breads'),
(16, 10, 'Vegetable Dishes', 'Plant-based entrees'),
(17, 11, 'Salads', 'Healthy greens and grains'),
(18, 12, 'Smoothies', 'Blended fruit and vegetable drinks');

-- Insert into Menu Item table
INSERT IGNORE INTO MenuItem (menu_item_id, menu_id, category_id, name, price, description)
VALUES
(1, 1, 1, 'Bruschetta', 5.99, 'Grilled bread topped with tomato and basil'),
(2, 1, 2, 'Spaghetti Carbonara', 13.99, 'Classic carbonara with bacon and egg'),
(3, 1, 2, 'Lasagna', 14.99, 'Layered pasta with meat and cheese'),
(4, 1, 3, 'Tiramisu', 7.99, 'Coffee-flavored Italian dessert'),
(5, 2, 4, 'Osso Buco', 22.99, 'Braised veal shanks with vegetables'),
(6, 2, 4, 'Risotto Milanese', 16.99, 'Saffron-infused creamy rice'),
(7, 3, 5, 'California Roll', 8.99, 'Crab, avocado, and cucumber'),
(8, 3, 5, 'Dragon Roll', 14.99, 'Eel and cucumber topped with avocado'),
(9, 3, 6, 'Salmon Sashimi', 12.99, 'Fresh sliced salmon'),
(10, 4, 7, 'Teriyaki Chicken Bento', 11.99, 'Chicken with rice and sides'),
(11, 4, 7, 'Tempura Bento', 13.99, 'Assorted tempura with rice'),
(12, 5, 8, 'Classic Cheeseburger', 9.99, 'Beef patty with cheese and lettuce'),
(13, 5, 8, 'Bacon BBQ Burger', 12.99, 'Burger with bacon and BBQ sauce'),
(14, 5, 9, 'French Fries', 3.99, 'Crispy golden fries'),
(15, 5, 9, 'Onion Rings', 4.99, 'Battered and fried onion rings'),
(16, 6, 10, 'Kids Slider Meal', 6.99, 'Mini burgers with fries'),
(17, 7, 11, 'Carne Asada Taco', 4.99, 'Grilled beef taco with cilantro'),
(18, 7, 11, 'Fish Taco', 5.99, 'Battered fish with slaw'),
(19, 7, 12, 'Chicken Burrito', 10.99, 'Grilled chicken with rice and beans'),
(20, 8, 13, 'Loaded Nachos', 11.99, 'Nachos with cheese, beans, and jalapenos'),
(21, 9, 14, 'Butter Chicken', 14.99, 'Creamy tomato chicken curry'),
(22, 9, 14, 'Lamb Vindaloo', 16.99, 'Spicy lamb curry'),
(23, 9, 15, 'Garlic Naan', 3.99, 'Traditional Indian bread'),
(24, 10, 16, 'Palak Paneer', 12.99, 'Spinach with cottage cheese'),
(25, 11, 17, 'Caesar Salad', 10.99, 'Romaine with dressing and croutons');

-- Insert into Employee table
INSERT IGNORE INTO Employee (employee_id, restaurant_id, name, phone_number, email, position)
VALUES
(1, 1, 'David Miller', '555-1122', 'david@restaurant.com', 'Chef'),
(2, 2, 'Emma Roberts', '555-2233', 'emma@restaurant.com', 'Waiter'),
(3, 3, 'Frank Williams', '555-3344', 'frank@restaurant.com', 'Manager'),
(4, 1, 'Grace Hopper', '555-1123', 'grace@restaurant.com', 'Waiter'),
(5, 1, 'Henry Ford', '555-1124', 'henry@restaurant.com', 'Manager'),
(6, 2, 'Irene Adler', '555-2234', 'irene@restaurant.com', 'Chef'),
(7, 3, 'Kate Moss', '555-3345', 'kate@restaurant.com', 'Chef'),
(8, 4, 'Maya Liu', '555-4401', 'maya@restaurant.com', 'Chef'),
(9, 4, 'Noah Cruz', '555-4402', 'noah@restaurant.com', 'Waiter'),
(10, 4, 'Olivia Perez', '555-4403', 'olivia@restaurant.com', 'Manager'),
(11, 5, 'Paul Rivera', '555-5501', 'paul@restaurant.com', 'Chef'),
(12, 5, 'Ryan Singh', '555-5503', 'ryan@restaurant.com', 'Manager'),
(13, 6, 'Sofia Rossi', '555-6601', 'sofia@restaurant.com', 'Chef'),
(14, 6, 'Tom Baker', '555-6602', 'tom@restaurant.com', 'Waiter'),
(15, 1, 'Vince Park', '555-1125', 'vince@restaurant.com', 'Delivery');

-- Insert into Tables table (must be done before Reservation to avoid FK error)
INSERT IGNORE INTO Tables (table_id, restaurant_id, capacity, status)
VALUES
(1, 1, 4, 'Available'),
(2, 1, 2, 'Reserved'),
(3, 1, 6, 'Available'),
(4, 2, 4, 'Reserved'),
(5, 2, 6, 'Available'),
(6, 2, 2, 'Available'),
(7, 3, 4, 'Occupied'),
(8, 3, 6, 'Available'),
(9, 3, 8, 'Reserved'),
(10, 4, 4, 'Available'),
(11, 4, 2, 'Reserved'),
(12, 5, 4, 'Available'),
(13, 5, 6, 'Available'),
(14, 6, 4, 'Available'),
(15, 6, 2, 'Reserved');

-- Insert into Customer table
INSERT IGNORE INTO Customer (customer_id, name, email, address, phone_number)
VALUES
(1, 'Alice Johnson', 'alice@example.com', '123 Main St, City', '555-1234'),
(2, 'Bob Smith', 'bob@example.com', '456 Oak St, Town', '555-5678'),
(3, 'Charlie Lee', 'charlie@example.com', '789 Pine St, Village', '555-8765'),
(4, 'Diana Chen', 'diana@example.com', '234 Birch Ln, City', '555-2345'),
(5, 'Edward Brown', 'edward@example.com', '567 Willow Dr, Town', '555-3456'),
(6, 'Fiona Taylor', 'fiona@example.com', '890 Poplar Blvd, Village', '555-4567'),
(7, 'George Harris', 'george@example.com', '345 Elm Ct, City', '555-5670'),
(8, 'Hannah Wilson', 'hannah@example.com', '678 Cedar Pl, Town', '555-6781'),
(9, 'Ian Murphy', 'ian@example.com', '901 Spruce Way, Village', '555-7892'),
(10, 'Julia Martinez', 'julia@example.com', '432 Ash St, City', '555-8903'),
(11, 'Kevin Nguyen', 'kevin@example.com', '765 Walnut Ave, Town', '555-9014'),
(12, 'Lily Anderson', 'lily@example.com', '198 Hickory Rd, Village', '555-0125'),
(13, 'Marcus Thompson', 'marcus@example.com', '543 Sycamore Ln, City', '555-1236'),
(14, 'Nina Patel', 'nina@example.com', '876 Magnolia Dr, Town', '555-2347'),
(15, 'Oscar Ramirez', 'oscar@example.com', '219 Chestnut Blvd, Village', '555-3458'),
(16, 'Paula Garcia', 'paula@example.com', '654 Redwood Ct, City', '555-4569'),
(17, 'Quinn Walker', 'quinn@example.com', '987 Dogwood Pl, Town', '555-5671'),
(18, 'Rachel Kim', 'rachel@example.com', '321 Fir Way, Village', '555-6782'),
(19, 'Steven Davis', 'steven@example.com', '432 Alder St, City', '555-7893'),
(20, 'Tina Robinson', 'tina@example.com', '876 Juniper Ave, Town', '555-8904');

-- Insert into Reservation table
INSERT IGNORE INTO Reservation (reservation_id, table_id, customer_id, restaurant_id, reservation_date_time, party_size, duration_minutes, status)
VALUES
(1, 1, 1, 1, '2024-12-05 18:30:00', 4, 90, 'completed'),
(2, 2, 2, 1, '2024-12-06 19:00:00', 2, 60, 'completed'),
(3, 4, 3, 2, '2024-12-07 20:00:00', 4, 90, 'completed'),
(4, 3, 4, 1, '2024-12-08 19:30:00', 5, 120, 'completed'),
(5, 5, 5, 2, '2024-12-09 18:00:00', 6, 120, 'completed'),
(6, 6, 6, 2, '2024-12-10 19:15:00', 2, 60, 'no_show'),
(7, 7, 7, 3, '2024-12-11 20:30:00', 3, 90, 'completed'),
(8, 8, 8, 3, '2024-12-12 18:45:00', 5, 120, 'completed'),
(9, 9, 9, 3, '2024-12-13 19:00:00', 8, 120, 'completed'),
(10, 10, 10, 4, '2024-12-14 20:00:00', 4, 90, 'cancelled'),
(11, 11, 11, 4, '2024-12-15 19:30:00', 2, 60, 'completed'),
(12, 12, 12, 5, '2024-12-16 18:00:00', 3, 90, 'completed'),
(13, 13, 13, 5, '2024-12-17 19:00:00', 6, 120, 'completed'),
(14, 14, 14, 6, '2024-12-18 20:00:00', 4, 90, 'completed'),
(15, 15, 15, 6, '2024-12-19 18:30:00', 2, 60, 'completed');

-- Insert into Orders table
INSERT IGNORE INTO Orders (order_id, customer_id, restaurant_id, order_date, total_amount, status)
VALUES
(1, 1, 1, '2024-12-01', 40.50, 'delivered'),
(2, 2, 1, '2024-12-02', 75.00, 'delivered'),
(3, 3, 2, '2024-12-03', 60.25, 'delivered'),
(4, 1, 1, '2024-12-05', 29.97, 'delivered'),
(5, 4, 2, '2024-12-05', 37.97, 'delivered'),
(6, 5, 3, '2024-12-06', 22.97, 'delivered'),
(7, 6, 3, '2024-12-07', 14.98, 'delivered'),
(8, 2, 4, '2024-12-08', 21.97, 'delivered'),
(9, 7, 4, '2024-12-09', 27.97, 'delivered'),
(10, 8, 5, '2024-12-09', 35.97, 'delivered'),
(11, 9, 5, '2024-12-10', 29.98, 'delivered'),
(12, 10, 6, '2024-12-10', 17.98, 'delivered'),
(13, 11, 1, '2024-12-11', 42.97, 'delivered'),
(14, 3, 2, '2024-12-12', 35.96, 'delivered'),
(15, 12, 3, '2024-12-12', 26.97, 'delivered'),
(16, 13, 4, '2024-12-13', 16.98, 'delivered'),
(17, 14, 5, '2024-12-14', 31.98, 'delivered'),
(18, 1, 1, '2024-12-15', 27.98, 'delivered'),
(19, 15, 6, '2024-12-15', 18.98, 'delivered'),
(20, 16, 2, '2024-12-16', 39.97, 'delivered'),
(21, 4, 3, '2024-12-16', 28.97, 'delivered'),
(22, 17, 4, '2024-12-17', 22.97, 'delivered'),
(23, 18, 5, '2024-12-17', 34.97, 'delivered'),
(24, 2, 1, '2024-12-18', 33.98, 'delivered'),
(25, 19, 6, '2024-12-18', 17.98, 'delivered'),
(26, 20, 1, '2024-12-19', 44.97, 'delivered'),
(27, 5, 4, '2024-12-19', 26.97, 'delivered'),
(28, 7, 5, '2024-12-20', 43.97, 'delivered'),
(29, 8, 2, '2024-12-20', 29.97, 'delivered'),
(30, 9, 3, '2024-12-21', 22.97, 'delivered');

-- Insert into Order Item table
INSERT IGNORE INTO OrderItem (order_item_id, order_id, menu_item_id, quantity, price)
VALUES
(1, 1, 1, 2, 5.99),
(2, 1, 2, 2, 13.99),
(3, 2, 5, 2, 22.99),
(4, 2, 3, 2, 14.99),
(5, 3, 8, 2, 14.99),
(6, 3, 7, 2, 8.99),
(7, 3, 9, 1, 12.99),
(8, 4, 1, 2, 5.99),
(9, 4, 4, 2, 7.99),
(10, 5, 10, 1, 11.99),
(11, 5, 11, 1, 13.99),
(12, 5, 7, 1, 8.99),
(13, 6, 12, 1, 9.99),
(14, 6, 14, 2, 3.99),
(15, 7, 13, 1, 12.99),
(16, 7, 14, 1, 3.99),
(17, 8, 17, 2, 4.99),
(18, 8, 20, 1, 11.99),
(19, 9, 19, 2, 10.99),
(20, 9, 18, 1, 5.99),
(21, 10, 21, 1, 14.99),
(22, 10, 23, 2, 3.99),
(23, 10, 24, 1, 12.99),
(24, 11, 22, 1, 16.99),
(25, 11, 23, 1, 3.99),
(26, 12, 25, 2, 10.99),
(27, 13, 5, 1, 22.99),
(28, 13, 2, 2, 13.99),
(29, 14, 8, 2, 14.99),
(30, 14, 10, 1, 11.99),
(31, 15, 12, 1, 9.99),
(32, 15, 13, 1, 12.99),
(33, 16, 17, 2, 4.99),
(34, 16, 18, 1, 5.99),
(35, 17, 21, 2, 14.99),
(36, 18, 1, 2, 5.99),
(37, 18, 4, 2, 7.99),
(38, 19, 25, 1, 10.99),
(39, 20, 8, 1, 14.99),
(40, 20, 9, 1, 12.99),
(41, 20, 11, 1, 13.99),
(42, 21, 13, 2, 12.99),
(43, 22, 19, 2, 10.99),
(44, 23, 22, 2, 16.99),
(45, 24, 3, 1, 14.99),
(46, 24, 2, 1, 13.99),
(47, 25, 25, 1, 10.99),
(48, 26, 5, 1, 22.99),
(49, 26, 6, 1, 16.99),
(50, 27, 20, 1, 11.99),
(51, 27, 17, 2, 4.99),
(52, 28, 21, 2, 14.99),
(53, 28, 24, 1, 12.99),
(54, 29, 11, 1, 13.99),
(55, 29, 10, 1, 11.99),
(56, 30, 12, 2, 9.99);

-- Insert into Payment table
INSERT IGNORE INTO Payment (payment_id, order_id, payment_type, payment_date)
VALUES
(1, 1, 'Credit Card', '2024-12-01'),
(2, 2, 'Cash', '2024-12-02'),
(3, 3, 'Debit Card', '2024-12-03'),
(4, 4, 'Credit Card', '2024-12-05'),
(5, 5, 'Mobile Pay', '2024-12-05'),
(6, 6, 'Cash', '2024-12-06'),
(7, 7, 'Credit Card', '2024-12-07'),
(8, 8, 'Debit Card', '2024-12-08'),
(9, 9, 'Mobile Pay', '2024-12-09'),
(10, 10, 'Credit Card', '2024-12-09'),
(11, 11, 'Cash', '2024-12-10'),
(12, 12, 'Credit Card', '2024-12-10'),
(13, 13, 'Debit Card', '2024-12-11'),
(14, 14, 'Mobile Pay', '2024-12-12'),
(15, 15, 'Credit Card', '2024-12-12'),
(16, 16, 'Cash', '2024-12-13'),
(17, 17, 'Debit Card', '2024-12-14'),
(18, 18, 'Credit Card', '2024-12-15'),
(19, 19, 'Mobile Pay', '2024-12-15'),
(20, 20, 'Credit Card', '2024-12-16'),
(21, 21, 'Cash', '2024-12-16'),
(22, 22, 'Debit Card', '2024-12-17'),
(23, 23, 'Credit Card', '2024-12-17'),
(24, 24, 'Mobile Pay', '2024-12-18'),
(25, 25, 'Cash', '2024-12-18'),
(26, 26, 'Credit Card', '2024-12-19'),
(27, 27, 'Debit Card', '2024-12-19'),
(28, 28, 'Mobile Pay', '2024-12-20'),
(29, 29, 'Credit Card', '2024-12-20'),
(30, 30, 'Cash', '2024-12-21');

-- Insert into Invoice table (one per payment; totals derive from Payment->Orders)
INSERT IGNORE INTO Invoice (invoice_id, payment_id, issue_date)
VALUES
(1, 1, '2024-12-01'),
(2, 2, '2024-12-02'),
(3, 3, '2024-12-03'),
(4, 4, '2024-12-05'),
(5, 5, '2024-12-05'),
(6, 6, '2024-12-06'),
(7, 7, '2024-12-07'),
(8, 8, '2024-12-08'),
(9, 9, '2024-12-09'),
(10, 10, '2024-12-09'),
(11, 11, '2024-12-10'),
(12, 12, '2024-12-10'),
(13, 13, '2024-12-11'),
(14, 14, '2024-12-12'),
(15, 15, '2024-12-12'),
(16, 16, '2024-12-13'),
(17, 17, '2024-12-14'),
(18, 18, '2024-12-15'),
(19, 19, '2024-12-15'),
(20, 20, '2024-12-16'),
(21, 21, '2024-12-16'),
(22, 22, '2024-12-17'),
(23, 23, '2024-12-17'),
(24, 24, '2024-12-18'),
(25, 25, '2024-12-18'),
(26, 26, '2024-12-19'),
(27, 27, '2024-12-19'),
(28, 28, '2024-12-20'),
(29, 29, '2024-12-20'),
(30, 30, '2024-12-21');

-- Insert into Delivery table
INSERT IGNORE INTO Delivery (delivery_id, order_id, employee_id, scheduled_time, actual_delivery_time, delivery_address, status)
VALUES
(1, 1, 15, '2024-12-01 19:30:00', '2024-12-01 20:00:00', '123 Main St, City', 'delivered'),
(2, 4, 15, '2024-12-05 19:00:00', '2024-12-05 19:30:00', '123 Main St, City', 'delivered'),
(3, 6, 7, '2024-12-06 20:00:00', '2024-12-06 20:15:00', '567 Willow Dr, Town', 'delivered'),
(4, 8, 9, '2024-12-08 20:30:00', '2024-12-08 21:00:00', '456 Oak St, Town', 'delivered'),
(5, 11, 11, '2024-12-10 19:30:00', '2024-12-10 19:45:00', '901 Spruce Way, Village', 'delivered'),
(6, 13, 15, '2024-12-11 20:00:00', '2024-12-11 20:30:00', '765 Walnut Ave, Town', 'delivered'),
(7, 17, 11, '2024-12-14 19:30:00', '2024-12-14 20:00:00', '876 Magnolia Dr, Town', 'delivered'),
(8, 21, 7, '2024-12-16 21:00:00', '2024-12-16 21:15:00', '234 Birch Ln, City', 'delivered'),
(9, 25, 14, '2024-12-18 18:30:00', '2024-12-18 19:00:00', '432 Alder St, City', 'delivered'),
(10, 28, 11, '2024-12-20 20:00:00', '2024-12-20 20:30:00', '345 Elm Ct, City', 'delivered');

-- Insert into Promotion table
INSERT IGNORE INTO Promotions (promotion_id, menu_item_id, start_date, end_date, name, discount_type, discount_value)
VALUES
(1, 1, '2024-12-01', '2024-12-31', 'Buy One Get One Free', 'PERCENTAGE', 50.00),
(2, 2, '2026-04-01', '2094-12-31', 'Lunch Special', 'PERCENTAGE', 15.00),
(3, 4, '2024-12-01', '2024-12-31', 'Happy Hour', 'FIXED', 2.00),
(4, 7, '2026-04-01', '2094-12-31', 'Sushi Saturday', 'PERCENTAGE', 20.00),
(5, 12, '2024-12-01', '2024-12-31', 'Burger Combo Deal', 'FIXED', 3.00),
(6, 17, '2026-04-01', '2094-12-31', 'Taco Tuesday', 'PERCENTAGE', 25.00),
(7, 21, '2026-04-01', '2094-12-31', 'Curry Night', 'PERCENTAGE', 10.00),
(8, 25, '2024-12-01', '2024-12-31', 'Healthy Week', 'FIXED', 1.50);

-- Insert into Supplier table
INSERT IGNORE INTO Supplier (supplier_id, restaurant_id, name, address, phone_number)
VALUES
(1, 1, 'Fresh Produce Co.', '789 Green St, City', '555-4444'),
(2, 2, 'Sushi Supplies Ltd.', '123 Sea St, Town', '555-5555'),
(3, 1, 'Cheese World', '123 Dairy Ave, City', '555-6666'),
(4, 3, 'Beef Masters', '456 Ranch Rd, Village', '555-7777'),
(5, 4, 'Tortilla Co.', '789 Corn St, City', '555-8888'),
(6, 5, 'Spice Traders', '321 Bazaar Ln, Town', '555-9999'),
(7, 6, 'Organic Farms', '654 Green Ave, Village', '555-0011'),
(8, 2, 'Ocean Fresh', '987 Harbor Rd, Town', '555-0022'),
(9, 3, 'Baker Bros.', '159 Mill St, Village', '555-0033'),
(10, 5, 'Rice Importers', '753 Grain Blvd, Town', '555-0044');

-- Insert into Ingredient table (master list, deduplicated)
INSERT IGNORE INTO Ingredient (ingredient_id, name, unit)
VALUES
(1, 'Tomato', 'kg'),
(2, 'Bacon', 'kg'),
(3, 'Pasta', 'kg'),
(4, 'Ground Beef', 'kg'),
(5, 'Cocoa', 'kg'),
(6, 'Veal', 'kg'),
(7, 'Saffron', 'g'),
(8, 'Crab', 'kg'),
(9, 'Avocado', 'each'),
(10, 'Eel', 'kg'),
(11, 'Salmon', 'kg'),
(12, 'Chicken Breast', 'kg'),
(13, 'Teriyaki Sauce', 'L'),
(14, 'Shrimp', 'kg'),
(15, 'Beef Patty', 'each'),
(16, 'Cheese', 'kg'),
(17, 'BBQ Sauce', 'L'),
(18, 'Potatoes', 'kg'),
(19, 'Onions', 'kg'),
(20, 'Chicken Tenders', 'kg'),
(21, 'Beef', 'kg'),
(22, 'White Fish', 'kg'),
(23, 'Rice', 'kg'),
(24, 'Tortilla Chips', 'kg'),
(25, 'Chicken Thigh', 'kg'),
(26, 'Lamb', 'kg'),
(27, 'Flour', 'kg'),
(28, 'Paneer', 'kg'),
(29, 'Romaine', 'kg'),
(30, 'Basil', 'g');

-- Insert into MenuItemIngredient (recipe junction)
INSERT IGNORE INTO MenuItemIngredient (menu_item_id, ingredient_id, quantity)
VALUES
(1, 1, 50), (1, 30, 8),
(2, 2, 20), (2, 3, 30),
(3, 4, 25),
(4, 5, 10),
(5, 6, 15),
(6, 7, 2),
(7, 8, 12), (7, 9, 20),
(8, 10, 8),
(9, 11, 25),
(10, 12, 30), (10, 13, 15),
(11, 14, 20),
(12, 15, 40), (12, 16, 50),
(13, 17, 15),
(14, 18, 60),
(15, 19, 35),
(16, 20, 20),
(17, 21, 25),
(18, 22, 18),
(19, 23, 40),
(20, 24, 30),
(21, 25, 28),
(22, 26, 18),
(23, 27, 50),
(24, 28, 15),
(25, 29, 40);

-- Insert into SupplierIngredient (who supplies what)
INSERT IGNORE INTO SupplierIngredient (supplier_id, ingredient_id, price_per_unit)
VALUES
(1, 1, 2.50), (1, 9, 0.80), (1, 18, 1.20), (1, 19, 1.00), (1, 29, 3.00), (1, 30, 0.05),
(2, 8, 18.00), (2, 10, 22.00), (2, 11, 20.00),
(3, 16, 8.50), (3, 28, 9.00),
(4, 4, 12.00), (4, 15, 1.20), (4, 21, 14.00),
(5, 24, 4.00), (5, 27, 1.50),
(6, 7, 2.00), (6, 13, 6.00), (6, 17, 5.50),
(7, 18, 1.10), (7, 19, 0.95), (7, 29, 2.80),
(8, 11, 19.50), (8, 14, 16.00), (8, 22, 12.00),
(9, 3, 2.20), (9, 27, 1.40),
(10, 23, 1.80);

-- Insert into Feedback table
INSERT IGNORE INTO Feedback (feedback_id, order_id, customer_id, rating, comment)
VALUES
(1, 1, 1, 5, 'Great food, will order again!'),
(2, 2, 2, 4, 'Tasty, but a bit too salty.'),
(3, 3, 3, 5, 'Delicious dessert, loved it!'),
(4, 4, 1, 5, 'Another great meal at Italian Bistro'),
(5, 5, 4, 4, 'Sushi was fresh and flavorful'),
(6, 6, 5, 3, 'Burger was okay but fries were cold'),
(7, 7, 6, 4, 'Quick service, kids loved it'),
(8, 8, 2, 5, 'Best tacos I have had!'),
(9, 10, 8, 5, 'The butter chicken was amazing'),
(10, 11, 9, 4, 'Good portion size for the price'),
(11, 12, 10, 3, 'Salad was fresh but small'),
(12, 13, 11, 5, 'Osso Buco was exceptional'),
(13, 15, 12, 4, 'Great burritos, will recommend'),
(14, 17, 14, 5, 'Loved the vegetarian options'),
(15, 18, 1, 4, 'Solid pasta dish'),
(16, 20, 16, 5, 'Authentic Japanese flavors'),
(17, 22, 17, 3, 'Average, nothing special'),
(18, 24, 2, 4, 'Italian classics done well'),
(19, 26, 20, 5, 'Excellent service and food'),
(20, 28, 7, 2, 'Disappointing, food was cold');

-- Insert into Shift table
INSERT IGNORE INTO Shift (shift_id, employee_id, start_time, end_time)
VALUES
(1, 1, '2024-12-01 10:00:00', '2024-12-01 18:00:00'),
(2, 2, '2024-12-02 12:00:00', '2024-12-02 20:00:00'),
(3, 3, '2024-12-03 14:00:00', '2024-12-03 22:00:00'),
(4, 4, '2024-12-01 16:00:00', '2024-12-02 00:00:00'),
(5, 5, '2024-12-02 09:00:00', '2024-12-02 17:00:00'),
(6, 6, '2024-12-03 11:00:00', '2024-12-03 19:00:00'),
(7, 7, '2024-12-04 10:00:00', '2024-12-04 18:00:00'),
(8, 8, '2024-12-05 12:00:00', '2024-12-05 20:00:00'),
(9, 9, '2024-12-06 14:00:00', '2024-12-06 22:00:00'),
(10, 10, '2024-12-07 16:00:00', '2024-12-08 00:00:00'),
(11, 11, '2024-12-08 09:00:00', '2024-12-08 17:00:00'),
(12, 12, '2024-12-09 11:00:00', '2024-12-09 19:00:00'),
(13, 13, '2024-12-10 10:00:00', '2024-12-10 18:00:00'),
(14, 14, '2024-12-11 12:00:00', '2024-12-11 20:00:00'),
(15, 15, '2024-12-12 14:00:00', '2024-12-12 22:00:00'),
(16, 1, '2024-12-13 10:00:00', '2024-12-13 18:00:00'),
(17, 2, '2024-12-14 12:00:00', '2024-12-14 20:00:00'),
(18, 3, '2024-12-15 14:00:00', '2024-12-15 22:00:00'),
(19, 4, '2024-12-16 16:00:00', '2024-12-17 00:00:00'),
(20, 5, '2024-12-17 09:00:00', '2024-12-17 17:00:00');

-- Insert into Loyalty Program table (enrollment record only)
INSERT IGNORE INTO LoyaltyProgram (loyalty_program_id, customer_id, joined_date)
VALUES
(1, 1, '2024-01-15'),
(2, 2, '2024-02-03'),
(3, 3, '2024-02-20'),
(4, 4, '2024-03-08'),
(5, 5, '2024-03-22'),
(6, 6, '2024-04-10'),
(7, 7, '2024-05-01'),
(8, 8, '2024-05-19'),
(9, 9, '2024-06-04'),
(10, 10, '2024-06-25'),
(11, 11, '2024-07-12'),
(12, 12, '2024-07-30'),
(13, 13, '2024-08-14'),
(14, 14, '2024-08-29'),
(15, 15, '2024-09-11'),
(16, 16, '2024-09-26'),
(17, 17, '2024-10-08'),
(18, 18, '2024-10-22'),
(19, 19, '2024-11-05'),
(20, 20, '2024-11-19');

-- Insert into LoyaltyTransaction table (1 point per dollar earned, plus a few redemptions)
INSERT IGNORE INTO LoyaltyTransaction (transaction_id, customer_id, order_id, points_delta, reason, created_at)
VALUES
(1, 1, 1, 40, 'order_earn', '2024-12-01 19:00:00'),
(2, 2, 2, 75, 'order_earn', '2024-12-02 19:30:00'),
(3, 3, 3, 60, 'order_earn', '2024-12-03 20:00:00'),
(4, 1, 4, 29, 'order_earn', '2024-12-05 19:00:00'),
(5, 4, 5, 37, 'order_earn', '2024-12-05 19:30:00'),
(6, 5, 6, 22, 'order_earn', '2024-12-06 20:00:00'),
(7, 6, 7, 14, 'order_earn', '2024-12-07 20:00:00'),
(8, 2, 8, 21, 'order_earn', '2024-12-08 20:30:00'),
(9, 7, 9, 27, 'order_earn', '2024-12-09 19:00:00'),
(10, 8, 10, 35, 'order_earn', '2024-12-09 19:30:00'),
(11, 9, 11, 29, 'order_earn', '2024-12-10 19:30:00'),
(12, 10, 12, 17, 'order_earn', '2024-12-10 20:00:00'),
(13, 11, 13, 42, 'order_earn', '2024-12-11 20:00:00'),
(14, 3, 14, 35, 'order_earn', '2024-12-12 19:00:00'),
(15, 12, 15, 26, 'order_earn', '2024-12-12 19:30:00'),
(16, 13, 16, 16, 'order_earn', '2024-12-13 19:00:00'),
(17, 14, 17, 31, 'order_earn', '2024-12-14 19:30:00'),
(18, 1, 18, 27, 'order_earn', '2024-12-15 19:00:00'),
(19, 15, 19, 18, 'order_earn', '2024-12-15 19:30:00'),
(20, 16, 20, 39, 'order_earn', '2024-12-16 20:00:00'),
(21, 4, 21, 28, 'order_earn', '2024-12-16 20:30:00'),
(22, 17, 22, 22, 'order_earn', '2024-12-17 19:00:00'),
(23, 18, 23, 34, 'order_earn', '2024-12-17 19:30:00'),
(24, 2, 24, 33, 'order_earn', '2024-12-18 19:00:00'),
(25, 19, 25, 17, 'order_earn', '2024-12-18 19:30:00'),
(26, 20, 26, 44, 'order_earn', '2024-12-19 20:00:00'),
(27, 5, 27, 26, 'order_earn', '2024-12-19 20:30:00'),
(28, 7, 28, 43, 'order_earn', '2024-12-20 20:00:00'),
(29, 8, 29, 29, 'order_earn', '2024-12-20 20:30:00'),
(30, 9, 30, 22, 'order_earn', '2024-12-21 20:00:00'),
(31, 4, NULL, 100, 'signup_bonus', '2024-03-08 12:00:00'),
(32, 9, NULL, 100, 'signup_bonus', '2024-06-04 12:00:00'),
(33, 16, NULL, 100, 'signup_bonus', '2024-09-26 12:00:00'),
(34, 1, NULL, -50, 'reward_redemption', '2024-12-22 10:00:00'),
(35, 7, NULL, -25, 'reward_redemption', '2024-12-22 11:00:00');

SELECT 'RestaurantOrderingSystemDB build complete.' AS status;
