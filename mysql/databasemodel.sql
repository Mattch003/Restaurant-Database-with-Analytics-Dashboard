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
