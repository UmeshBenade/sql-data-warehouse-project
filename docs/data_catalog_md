# Data Catalog for Gold Layer

## Overview

The **Gold Layer** is the business-level data representation of the data warehouse, structured to support analytical and reporting use cases.

It consists of **dimension tables** and **fact tables** designed to provide clean, business-ready data for analysis.

---

## 1. `gold.dim_customers`

**Purpose:**
Stores customer details enriched with demographic and geographic information.

### Columns

| Column Name       | Data Type    | Description                                                                           |
| ----------------- | ------------ | ------------------------------------------------------------------------------------- |
| `customer_key`    | INT          | Surrogate key uniquely identifying each customer record in the dimension table.       |
| `customer_id`     | INT          | Unique numerical identifier assigned to the customer.                                 |
| `customer_number` | NVARCHAR(50) | Alphanumeric identifier representing the customer, used for tracking and referencing. |
| `first_name`      | NVARCHAR(50) | The customer's first name, as recorded in the system.                                 |
| `last_name`       | NVARCHAR(50) | The customer's last name or family name.                                              |
| `country`         | NVARCHAR(50) | The country of residence for the customer, such as `Australia`.                       |
| `marital_status`  | NVARCHAR(50) | The marital status of the customer, such as `Married` or `Single`.                    |
| `gender`          | NVARCHAR(50) | The gender of the customer, such as `Male`, `Female`, or `n/a`.                       |
| `birthdate`       | DATE         | The date of birth of the customer, stored in `YYYY-MM-DD` format.                     |
| `create_date`     | DATE         | The date when the customer record was created in the system.                          |

---

## 2. `gold.dim_products`

**Purpose:**
Provides information about products and their attributes.

### Columns

| Column Name            | Data Type    | Description                                                                                                     |
| ---------------------- | ------------ | --------------------------------------------------------------------------------------------------------------- |
| `product_key`          | INT          | Surrogate key uniquely identifying each product record in the product dimension table.                          |
| `product_id`           | INT          | Unique identifier assigned to the product for internal tracking and referencing.                                |
| `product_number`       | NVARCHAR(50) | Structured alphanumeric code representing the product, commonly used for identification and inventory tracking. |
| `product_name`         | NVARCHAR(50) | Descriptive name of the product, including key details such as type, color, and size.                           |
| `category_id`          | NVARCHAR(50) | Unique identifier for the product category, linking the product to its high-level classification.               |
| `category`             | NVARCHAR(50) | Broader classification of the product, such as `Bikes` or `Components`.                                         |
| `subcategory`          | NVARCHAR(50) | More detailed classification of the product within its category.                                                |
| `maintenance_required` | NVARCHAR(50) | Indicates whether the product requires maintenance, such as `Yes` or `No`.                                      |
| `cost`                 | INT          | Cost or base price of the product, measured in monetary units.                                                  |
| `product_line`         | NVARCHAR(50) | The specific product line or series to which the product belongs, such as `Road` or `Mountain`.                 |
| `start_date`           | DATE         | The date when the product became available for sale or use.                                                     |

---

## 3. `gold.fact_sales`

**Purpose:**
Stores transactional sales data for analytical and reporting purposes.

### Columns

| Column Name     | Data Type    | Description                                                                    |
| --------------- | ------------ | ------------------------------------------------------------------------------ |
| `order_number`  | NVARCHAR(50) | Unique alphanumeric identifier for each sales order, such as `SO54496`.        |
| `product_key`   | INT          | Surrogate key linking the sales transaction to the product dimension.          |
| `customer_key`  | INT          | Surrogate key linking the sales transaction to the customer dimension.         |
| `order_date`    | DATE         | The date when the order was placed.                                            |
| `shipping_date` | DATE         | The date when the order was shipped to the customer.                           |
| `due_date`      | DATE         | The date when payment for the order was due.                                   |
| `sales_amount`  | INT          | Total monetary value of the sales line item, measured in whole currency units. |
| `quantity`      | INT          | Number of units of the product ordered for the sales line item.                |
| `price`         | INT          | Price per unit of the product, measured in whole currency units.               |

---

## Gold Layer Model Overview

The Gold Layer follows a **star schema** design, where the `fact_sales` table acts as the central fact table and connects to descriptive dimension tables.

### Fact Table

* `gold.fact_sales`

  * Contains sales transactions and measurable business metrics.
  * Stores foreign keys to customer and product dimensions.

### Dimension Tables

* `gold.dim_customers`

  * Provides customer-related descriptive attributes.

* `gold.dim_products`

  * Provides product-related descriptive attributes.

### Relationships

```text
                    gold.dim_customers
                           |
                           | customer_key
                           |
                           v
                    gold.fact_sales
                           ^
                           |
                           | product_key
                           |
                    gold.dim_products
```

This structure allows analysts to efficiently answer business questions such as:

* What are the total sales by customer?
* Which products generate the most revenue?
* What are the sales trends over time?
* Which product categories perform best?
* How many products has each customer purchased?
