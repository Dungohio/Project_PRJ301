USE [master]
GO

/*******************************************************************************
   Drop database if it exists
********************************************************************************/
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'prj301ebay')
BEGIN
	ALTER DATABASE prj301ebay SET OFFLINE WITH ROLLBACK IMMEDIATE;
	ALTER DATABASE prj301ebay SET ONLINE;
	DROP DATABASE prj301ebay;
END

GO

CREATE DATABASE prj301ebay
GO

USE prj301ebay
GO

/*******************************************************************************
	Drop tables if exists
*******************************************************************************/
DECLARE @sql nvarchar(MAX) 
SET @sql = N'' 

SELECT @sql = @sql + N'ALTER TABLE ' + QUOTENAME(KCU1.TABLE_SCHEMA) 
    + N'.' + QUOTENAME(KCU1.TABLE_NAME) 
    + N' DROP CONSTRAINT ' -- + QUOTENAME(rc.CONSTRAINT_SCHEMA)  + N'.'  -- not in MS-SQL
    + QUOTENAME(rc.CONSTRAINT_NAME) + N'; ' + CHAR(13) + CHAR(10) 
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS RC 

INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU1 
    ON KCU1.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG  
    AND KCU1.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA 
    AND KCU1.CONSTRAINT_NAME = RC.CONSTRAINT_NAME 

EXECUTE(@sql) 

GO
DECLARE @sql2 NVARCHAR(max)=''

SELECT @sql2 += ' Drop table ' + QUOTENAME(TABLE_SCHEMA) + '.'+ QUOTENAME(TABLE_NAME) + '; '
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_TYPE = 'BASE TABLE'

Exec Sp_executesql @sql2 
GO 

--use prj301ebay database
use prj301ebay;
GO

-- Create 16 tables
create table ProductType (
	product_type_id	tinyint identity(1,1) not null primary key,
	product_type		nvarchar(20) not null
);

GO

create table Product (
	product_id		smallint identity(1,1) not null primary key,
	product_name		nvarchar(500) not null,
	product_description	nvarchar(2000) null,
	product_price		money not null,
    	product_limit		smallint not null,
	product_status		bit not null,
	product_rate		tinyint null,
	discount_price		tinyint not null,
	product_img_url		varchar(400) not null,
	product_type_id		tinyint not null foreign key references ProductType(product_type_id)
);

GO

create table [Admin] (
	admin_id		tinyint identity(1,1) not null primary key,
	admin_fullname		nvarchar(200) not null,
);

GO

create table AdminProduct (
	admin_id		tinyint not null foreign key references [Admin](admin_id),
	product_id			smallint not null foreign key references Product(product_id)
);

GO

create table Staff (
	staff_id		tinyint identity(1,1) not null primary key,
	staff_fullname		nvarchar(200) not null,
);

GO

create table Voucher (
	voucher_id			tinyint identity(1,1) not null primary key,
	voucher_name			nvarchar(200) not null,
	voucher_code			char(16) not null,
	voucher_discount_percent	tinyint not null,
	voucher_quantity		tinyint not null,
	voucher_status			bit not null,
	voucher_date			datetime not null
);

GO

create table PromotionManager (
	pro_id			tinyint identity(1,1) not null primary key,
	pro_fullname		nvarchar(200) not null,
);

GO

create table Customer (
	customer_id		int identity(1,1) not null primary key,
	customer_firstname	nvarchar(200) not null,
	customer_lastname	nvarchar(200) not null,
	customer_gender		nvarchar(5) not null,
	customer_phone		varchar(11) not null,
	customer_address	nvarchar(1000) not null
);

GO

-- Create index for Customer table to improve search performance
create index idx_customer_firstname_lastname_gender_phone_address
on Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address);

GO

create table Account (
	account_id		int identity(1,1) not null primary key,
	customer_id		int null foreign key references Customer(customer_id),
	staff_id		tinyint null foreign key references Staff(staff_id),
	pro_id			tinyint null foreign key references PromotionManager(pro_id),
	admin_id		tinyint null foreign key references [Admin](admin_id),
	account_username	nvarchar(100) not null,
	account_email		nvarchar(500) not null,
	account_password	char(32) not null,
	account_type		varchar(20) not null,
	lastime_order 		datetime null
);

GO

create table Cart (
	cart_id			int identity(1,1) not null primary key,
	customer_id		int not null foreign key references Customer(customer_id)
);

GO

create table CartItem (
	cart_item_id		int identity(1,1) not null primary key,
	cart_id			int not null foreign key references Cart(cart_id),
	product_id		smallint not null foreign key references Product(product_id),
	product_price		money not null,
	product_quantity	tinyint not null
);

GO

create table OrderStatus (
	order_status_id		tinyint identity(1,1) not null primary key,
	order_status		nvarchar(50) not null
);

GO

create table PaymentMethod (
	payment_method_id	tinyint identity(1,1) not null primary key,
	payment_method		nvarchar(50) not null
);

GO

create table [Order] (
	order_id		int identity(1,1) not null primary key,
	cart_id			int not null foreign key references Cart(cart_id),
	customer_id		int not null foreign key references Customer(customer_id),
	order_status_id		tinyint not null foreign key references OrderStatus(order_status_id),
	payment_method_id	tinyint not null foreign key references PaymentMethod(payment_method_id),
	voucher_id		tinyint null foreign key references Voucher(voucher_id),
	contact_phone		varchar(11) not null,
	delivery_address	nvarchar(500) not null,
	order_time		datetime not null,
	order_total		money not null,
	order_note		nvarchar(1023) null,
	delivery_time		datetime null,
	order_cancel_time	datetime null
);

GO

create table Payment (
    order_id                int not null foreign key references [Order](order_id),
    payment_method_id       tinyint not null foreign key references PaymentMethod(payment_method_id),
    payment_total           money not null,
    payment_content         nvarchar(1023) null,
    payment_bank            nvarchar(50) null,
    payment_code            varchar(20) null,
    payment_status          tinyint not null,
    payment_time            datetime not null
);

GO

create table OrderLog (
    log_id				int identity(1,1) not null primary key,
    order_id            int not null foreign key references [Order](order_id),
    staff_id			tinyint null foreign key references Staff(staff_id),
    admin_id			tinyint null foreign key references [Admin](admin_id),
    log_activity        nvarchar(100) not null,
    log_time            datetime not null
);

GO

--Use prj301ebay database
USE prj301ebay
GO

--Set status of product = 0 if limit = 0
CREATE TRIGGER tr_UpdateProductStatus
ON Product
AFTER UPDATE
AS
BEGIN
    IF UPDATE(product_limit)
    BEGIN
        UPDATE Product
        SET product_status = 0
        WHERE product_limit = 0;
    END
END;

GO

-- Inactivate product when delete
CREATE TRIGGER tr_InactivateProduct
ON Product
INSTEAD OF DELETE
AS
BEGIN
    UPDATE Product
    SET product_status = 0
    WHERE product_id IN (SELECT product_id FROM deleted);
END;

GO

-- Remove cart after customer deleted
CREATE TRIGGER tr_delete_cart_links
ON Account
AFTER DELETE
AS
BEGIN
    DELETE FROM Cart WHERE customer_id IN (SELECT deleted.customer_id FROM deleted);
END

GO

-- Don't delete when still have order
CREATE TRIGGER tr_prevent_delete_customer
ON Customer
INSTEAD OF DELETE
AS
BEGIN
    IF (EXISTS (SELECT 1 FROM Cart WHERE customer_id = (SELECT customer_id FROM deleted)) OR
        EXISTS (SELECT 1 FROM [Order] WHERE customer_id = (SELECT customer_id FROM deleted)))
    BEGIN
        RAISERROR('Cannot delete customer with active cart or orders.', 16, 1)
    END
    ELSE
    BEGIN
        DELETE FROM Customer WHERE customer_id = (SELECT customer_id FROM deleted)
    END
END

GO

--Use prj301ebay database
use prj301ebay;

-- Insert Admin records
insert into [Admin] (admin_fullname) values (N'Vũ Hoàng Minh');
insert into [Admin] (admin_fullname) values (N'Nguyễn Hoàng Dũng');
insert into [Admin] (admin_fullname) values (N'Ngô Đức Huy');
insert into [Admin] (admin_fullname) values (N'Nguyễn Mậu Hiếu');

-- Insert Account records for Admins
-- Admin passwords are 'admin#' where # ranges from 1 to 4
-- Hash the passwords using MD5 algorithm
-- Admin passwords = 1234
-- Admin account ID starts from 1-20

INSERT INTO Account (admin_id, account_username, account_email, account_password, account_type) VALUES (1, N'hoangminh123', N'minhvhhe186900@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (2, N'hoangdung123', N'dungnhhe180993@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (3, N'huyngo123', N'huyndhe186674@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (4, N'hieunguyen123', N'hieunmhe181441@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');

-- Staffs must be added before an associated Account (if exists) can be created
insert into Staff (staff_fullname) values (N'Test Staff Một');
insert into Staff (staff_fullname) values (N'Test Staff Hai');
insert into Staff (staff_fullname) values (N'Test Staff Ba');
insert into Staff (staff_fullname) values (N'Test Staff Bốn');

-- Reset the identity seed for the Account table to 20
-- Staffs' account ID starts from 21-40
dbcc checkident (Account, RESEED, 50);
-- Insert Staff Account
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (1, N'testStaff1', N'teststaff1@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (2, N'testStaff2', N'teststaff2@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (3, N'testStaff3', N'teststaff3@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (4, N'testStaff4', N'teststaff4@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');


-- Insert test promotion manager account
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Một');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Hai');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Ba');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Bốn');

-- Promotion managers' account ID starts from 41-50
dbcc checkident (Account, RESEED, 100);
-- Insert Promotion Manager Account
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (1, N'testPromotion1', N'testPromotion1@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (2, N'testPromotion2', N'testPromotion2@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (3, N'testPromotion3', N'testPromotion3@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (4, N'testPromotion4', N'testPromotion4@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');



-- Customer must be added before an associated Account (if exists) can be created
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Quốc Anh', N'Nguyễn', N'Nam', '0914875606', N'Đường sô 3, Khu Vực Bình thường B, Bình Thủy, Cần Thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Khắc Huy', N'Huỳnh', N'Nam', '0375270803', N'132/24D, đường 3-2, Ninh Kiều Cần Thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Vũ Như Huỳnh', N'Nguyễn', N'Nữ', '0896621155', N'34, B25, Kdc 91B, An Khánh, Ninh Kiều');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Tiến Thành', N'Hứa', N'Nam', '0912371282', N'39 Mậu Thân, Xuân Khánh, Ninh Kiều, Cần Thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Hoàng Khang', N'Nguyễn', N'Nam', '0387133745', N'110/22/21 Trần Hưng Đạo, Bình Thỷ, Cần thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Duy Khang', N'Huỳnh', N'Nam', '0913992409', N'138/29/21 Trần Hưng Đạo, Ninh Kiều, Cần thơ');
dbcc checkident (Account, RESEED, 200);
-- Insert Customer Account
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (1, N'quocanh123', N'anhnq1130@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (2, N'hkhachuy', N'hkhachuy.dev@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (3, N'rainyvuwritter', N'rainyvuwritter@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (4, N'huatienthanh2003', N'huatienthanh2003@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (5, N'khangnguyen', N'khgammingcraft@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (6, N'hdkhang2112', N'hdkhang2112@gmail.com ', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');

-- Insert Product Types
insert into ProductType (product_type) values (N'Bag & Backpack');
insert into ProductType (product_type) values (N'Shoes');
insert into ProductType (product_type) values (N'Jewelry & Accessory');
insert into ProductType (product_type) values (N'P & A');
insert into ProductType (product_type) values (N'Baby');
insert into ProductType (product_type) values (N'Stationery');
insert into ProductType (product_type) values (N'Health & Beauty');
insert into ProductType (product_type) values (N'Clothing');

-- Ensure product_id starts from 1
dbcc checkident (Product, RESEED, 0);
-- Bag & Backpack
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)   
values (1, N'Waterproof Madame Graffiti Travel Bag','This personalized travel bag is all about style. Made with high-grade waterproof nylon', 30.99, 100, 1, 0, 'https://m.media-amazon.com/images/I/71xhEBxc4WL._AC_UY1000_.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'COACH Times Square Tabby Shoulder Bag','Inspired by the dynamic energy of our hometown New York City, the Times Square Tabby is a modern take on an archival 1970s Coach design.', 50.29, 40, 1, 5, 'https://s7d2.scene7.com/is/image/Coach/cw629_b4bk_a0?fmt=jpg&wid=711&hei=888&qlt=80%2C1&op_sharpen=0&resMode=bicub&op_usm=5%2C0.2%2C0%2C0&iccEmbed=0&fit=vfit');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'STELLA McCARTNEY Falabella Mini Shoulder Bag','At Stella McCartney, great innovations come in small packages too. Our range of vegan mini bags and clutches are made from 100% cruelty-free materials.', 45.99, 50, 1, 0, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ2NyUJ_ybujRt9xWawz6eQVcuhEERsyzFh3w&s');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'VALENTINO BAGS - Bigs Crossbody','Valentino Bags Bigs shoulder bag unfolds to reveal a remarkably roomy interior, featuring two open compartments and one secured by a zipper.', 190.2, 70, 0, 30, 'https://img01.ztat.net/article/spp-media-p1/0f13c0fd722231678b8ebd9e404c990b/830bc43a35af43adb321b5e76cf75deb.jpg?imwidth=1800&filter=packshot');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'Fjällräven Kånken Backpack','Fjällräven Kånken is a classic backpack, known for its square shape and functional, durable design. It is perfect for both school and everyday use.', 90.99, 120, 1,10, 'https://m.media-amazon.com/images/I/71uvsxViofL._AC_UY1000_.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'Osprey Farpoint 40 Travel Backpack','The Osprey Farpoint 40 is a versatile travel backpack with plenty of room for all your essentials, perfect for adventures near or far.', 120.99, 80, 1, 15, 'https://m.media-amazon.com/images/I/81tbav1HsSL._AC_SL1500_.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'Timbuk2 Authority Laptop Backpack','This backpack is ideal for professionals on the go. It includes a dedicated laptop compartment and ample space for organizing your work essentials.', 130.49, 60, 1, 5, 'https://www.timbuk2.com/cdn/shop/products/timbuk2-authority-laptop-backpack-deluxe-eco-titanium-1825-3-1089-front_1_1024x1024.png?v=1664825257');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'Prada Re-Edition Nylon Bag','This elegant Prada nylon bag is a re-edition of their iconic 2005 design. Made with recycled materials, it combines sustainability with style.', 299.99, 30, 1, 10, 'https://cdn-images.farfetch-contents.com/19/66/19/46/19661946_43929832_1000.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'Herschel Supply Co. Classic Backpack','The Herschel Classic Backpack offers simple, durable design for everyday use, complete with a spacious main compartment and front pocket.', 59.99, 150, 1, 0, 'https://product.hstatic.net/200000725249/product/alo-herschel-classic-standard-15-backpack-m-gargoyle-13189-01658572077_cb99d57720714feba565cb72b24ca1bb_master.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (1, N'Louis Vuitton Neverfull MM','This Louis Vuitton Neverfull MM is a spacious and iconic tote bag that complements any wardrobe, crafted from premium materials.', 1250.00, 20, 1, 20, 'https://vn.louisvuitton.com/images/is/image/lv/1/PP_VP_L/louis-vuitton-neverfull-mm--N40599_PM2_Front%20view.jpg');

-- Shoes
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (2, N'Nike Air Max 270','The Nike Air Max 270 is engineered for all-day comfort and style. Featuring a large air unit for cushion and a sleek, modern design.', 150.99, 100, 1, 0, 'https://static.nike.com/a/images/t_PDP_936_v1/f_auto,q_auto:eco/gorfwjchoasrrzr1fggt/AIR+MAX+270.png');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Adidas Ultraboost 22','Designed for running enthusiasts, the Adidas Ultraboost 22 offers unparalleled comfort, a snug fit, and advanced performance technology.', 180.49, 80, 1, 10, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbl3vEmqR3UsF5J6H74YQDD67-Fr2XXrE3kg&s');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (2, N'Converse Chuck Taylor All Star','The Converse Chuck Taylor All Star is a timeless sneaker that offers a durable canvas upper and classic design for everyday wear.', 70.00, 120, 1, 5, 'https://product.hstatic.net/200000265619/product/568497c-thumb-web_19a679fd48aa48a4a50eae354087309c_1024x1024.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Vans Old Skool','Vans Old Skool is a classic skate shoe with a durable suede and canvas upper, padded tongue and lining, and the signature rubber waffle outsole.', 60.00, 90, 1, 0, 'https://bizweb.dktcdn.net/100/140/774/products/vans-old-skool-black-white-vn000d3hy28-2.jpg?v=1625905148527');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Birkenstock Arizona Sandals','The Birkenstock Arizona Sandals are known for their contoured cork footbed and adjustable straps, offering excellent comfort and support.', 100.99, 50, 1, 15, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvEwfgfo5AmTr56UH2RpPGyUfppCA9eTKmUg&s');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Gucci Ace Leather Sneakers','The Gucci Ace Leather Sneakers bring high-end luxury to casual footwear, crafted from premium materials and adorned with iconic branding.', 650.00, 30, 1, 10, 'https://24cara.vn/wp-content/uploads/2019/09/652233232232.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Adidas Yeezy Boost 350 V2','The Adidas Yeezy Boost 350 V2 is a standout in streetwear, combining Kanye West’s visionary design with Adidas’s technical innovation.', 220.00, 40, 1, 20, 'https://sonauthentic.com/public/thumbs/800x0x1/90_giay-adidas-yeezy-boost-350-v2-beluga-reflective-gw1229-oQA6IC9lBK.webp');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url) 
values (2, N'Dr. Martens 1460 Boots','Dr. Martens 1460 is a classic lace-up boot with a durable leather upper, grooved edges, and signature yellow stitching, offering a tough, timeless style.', 140.00, 70, 1, 0, 'https://vn-test-11.slatic.net/p/e810edf42d12362245ff94c03ceaae80.jpg');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Crocs Classic Clog','Crocs Classic Clog offers a lightweight, comfortable fit with durable foam cushioning and ventilation ports for breathability.', 45.99, 200, 1, 5, 'https://www.crocs.com.vn/cdn/shop/products/10001-2Y2-2_1400x.jpg?v=1664259807');

insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status,  discount_price, product_img_url) 
values (2, N'Puma RS-X3 Puzzle Sneakers','The Puma RS-X3 Puzzle Sneakers are known for their bold, futuristic design and cushioned sole, blending streetwear style with performance.', 110.00, 60, 1, 10, 'https://ktsneaker.com/upload/product/4-1845.jpg');

-- Jewelry & Accessory
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Cá kho tộ','Cá kho tộ là một món ăn truyền thống của Việt Nam, được làm từ cá kho với nước mắm, đường, hành, tỏi và ớt. Món ăn có vị đậm đà, ngọt ngào và cay cay, thường được ăn với cơm trắng và rau sống.', 80000, 10, 1, 5, 0, 'https://bepmina.vn/wp-content/uploads/2023/07/cach-lam-ca-ba-sa-kho-to.jpeg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Sashimi','Sashimi là món hải sản tươi sống cắt thành lát mỏng, thường là cá hoặc hải sản khác, được phục vụ không cần nấu chín, thường kèm theo muối, rau sống và wasabi.', 120000, 20, 1, 5, 0, 'https://images.immediate.co.uk/production/volatile/sites/30/2020/02/sashimi-c123df7.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)     
VALUES (3, N'Scallops','Scallops là một loại hải sản ngon và bổ dưỡng, có hình dạng như những chiếc vỏ sò tròn. Thịt scallops mềm và ngọt, có thể chế biến theo nhiều cách khác nhau, như nướng, chiên, hấp, hoặc xào.', 150000, 10, 0, 5, 15, 'https://www.onceuponachef.com/images/2022/03/how-to-cook-scallops-2-scaled.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Seaweed Salad','Salad Rong Biển, như một bữa tiệc dưới biển! Rong biển mềm mại, giòn, kèm theo gia vị tinh tế, tạo nên một trải nghiệm ăn mới lạ và ngon miệng!', 50000, 20, 1, 5, 20, 'https://valuemartgrocery.com/cdn/shop/products/Seaweed-Salad-Reshoot-6-scaledsquare_1024x1024.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Shrimp and Grits','Cái Grits là một món ăn ngon từ miền Nam nước Mỹ. Nó bao gồm miếng tôm tươi tắn chín tới, hòa quyện với hương vị giàu bơ và công thức riêng của riêng quán tôi. Một món ăn đậm chất Mỹ, tạo nên trải nghiệm đầy thú vị cho vị giác của bạn.', 90000, 30, 1, 5, 0, 'https://www.bowlofdelicious.com/wp-content/uploads/2018/08/Easy-Classic-Shrimp-and-Grits-square.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Lobster Bisque','Lobster Bisque là một loại súp ngon không tả được, được làm từ tôm hùm tươi và hòa quyện với các loại gia vị. Một giọt mỗi sẽ mang đến cảm giác ngọt ngào và hấp dẫn, chắc chắn sẽ làm bạn ghiền.', 130000, 5, 0, 5, 0, 'https://cafedelites.com/wp-content/uploads/2020/02/Lobster-Bisque-IMAGE-1jpg.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Lobster Roll Sandwich','Món bánh mì Lobster Roll thơm ngon với tôm hùm tươi sống, thịt tôm mềm mịn, được trộn cùng mỳ và gia vị đặc trưng. Hương vị đậm đà, quyến rũ, làm say lòng mọi thực khách.', 140000, 20, 1, 5, 30, 'https://www.eatingwell.com/thmb/ZrNy9pvrIiCo_PVC5G6EH-jlP28=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/lobster-roll-ck-226594-4x3-1-b3aea3b5cd3e46b6820e2ca6a5c7b310.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)     
VALUES (3, N'Ceviche','Cá Ceviche là món ăn từ hải sản sống trong nước mắm chanh, măng, và rau thơm. Miếng cá mềm, chua chua, ngon lành, kích thích vị giác.', 70000, 20, 1, 5, 0, 'https://hips.hearstapps.com/hmg-prod/images/ceviche-index-64887642e188d.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Crab Cakes','Bánh đập cua thơm ngon là một món ngon rất phổ biến, được làm từ cua tươi ngon, kết hợp với các loại gia vị tinh tế và giòn tan bên ngoài, bên trong mềm mịn. Hương vị của bánh đập cua sẽ khiến bạn mê mẩn chỉ trong một lần thưởng thức.', 100000, 30, 1, 5, 20, 'https://hips.hearstapps.com/hmg-prod/images/crab-cakes-index-64e7cee7d4dda.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Grilled Salmon','Cá hồi nướng giữ nguyên vị biển mặn, thịt mềm, nước sốt dầu ôliu nhẹ nhàng làm nổi bật hương vị tươi ngon của cá. Thêm cảm giác ngon miệng vào bữa ăn của bạn!', 110000, 3, 0, 5, 0, 'https://www.acouplecooks.com/wp-content/uploads/2020/05/Grilled-Salmon-015-1.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Mussels','Nghệ thuật biến những con trai đỏ tươi thành món hấp dẫn đầy hương vị. Nước mắt của biển, hòa quyện với sự tươi mới của những cánh hoa hồng. Một đĩa mực tươi ngon chờ bạn khám phá.', 60000, 20, 1, 5, 0, 'https://www.healthyseasonalrecipes.com/wp-content/uploads/2023/01/simple-steamed-mussels-with-garlic-sq-041.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Oysters','Hàu là một loại thực phẩm biển, có vỏ cứng và thịt mềm. Hàu có nhiều chất dinh dưỡng, như protein, canxi, sắt và kẽm. Hàu có thể ăn sống hoặc chế biến theo nhiều cách, như nướng, hấp, chiên hoặc nấu canh.', 90000, 50, 1, 5, 0, 'https://static.emerils.com/grilled%20oysters.jpeg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (3, N'Tuna Tartare','Tartare cá ngừ là một món ăn thú vị với cá ngừ tươi ngon được cắt nhỏ và trộn với các loại gia vị tươi mát. Món ăn này có hương vị hòa quyện, tươi ngon và đậm đà, thật tuyệt!', 120000, 30, 1, 5, 15, 'https://pinchandswirl.com/wp-content/uploads/2022/12/Tuna-Tartare-sq.jpg');


-- P & A
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (4, N'Cao lầu','Cao lầu là một món ăn đặc trưng của Hội An, gồm mì trộn nước sốt, thịt xá xíu, rau thơm và bánh phồng giòn. Món ăn có hương vị đậm đà, ngọt thanh và thơm mùi nước mắm.', 55000, 20, 1, 5, 0, 'https://img-global.cpcdn.com/recipes/2940d93145814c54/680x482cq70/cao-l%E1%BA%A7u-h%E1%BB%99i-an-fake-recipe-main-photo.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (4, N'Cháo lòng','Chào bạn, cháo lòng là một món ăn truyền thống của Việt Nam, được làm từ gạo và các bộ phận nội tạng của lợn, như tim, gan, ruột, phổi, thận, v.v. Cháo lòng có vị ngọt, béo, thơm và đậm đà, thường được ăn kèm với bánh quẩy giòn rụm hoặc rau sống. Cháo lòng là món ăn lý tưởng cho những ngày se lạnh hoặc khi bạn cần bổ sung năng lượng.', 40000, 15, 0, 5, 20, 'https://diadiemlongkhanh.cdn.vccloud.vn/static/images/2022/06/08/ee1023df-7261-4b67-b939-9aef34e0d33e-image.jpeg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (4, N'Com tấm','Com tấm, là một bữa trưa Việt thơm ngon và đơn giản. Cơm mềm, xôi béo, thêm mỡ hành, chả trứng và sốt nước mắm tạo nên hương vị tuyệt vời.', 30000, 50, 1, 5, 0, 'https://i.ytimg.com/vi/6luZIIX5yCM/maxresdefault.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (4, N'Gỏi cuốn','Gỏi cuốn là món ăn Việt Nam ngon miệng và tươi mát. Nó được làm từ lá trái cây, rau, tôm, thịt và được gói trong một chiếc bánh trắng mỏng để tạo ra một công thức ăn nhẹ nhàng và ngon lành.', 35000, 30, 1, 5, 15, 'https://www.cet.edu.vn/wp-content/uploads/2018/11/goi-cuon-tom-thit.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (4, N'Nem chua','Nem chua là một món ăn truyền thống của Việt Nam. Được làm từ thịt heo tươi, thường có vị chua nhẹ và thơm mùi lá chuối. Nem chua thường được ăn kèm với rau sống và nước mắm.', 25000, 20, 1, 5, 0, 'https://statics.vinpearl.com/nem-chua-1_1628326267.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)     
VALUES (4, N'Xôi xéo','Xôi xéo là một món ăn truyền thống của người Việt Nam, được làm từ gạo nếp nấu chín và trộn với nghệ vàng. Xôi xéo thường được ăn kèm với đậu xanh, hành phi, chà bông và dầu ăn. Món ăn có màu vàng sáng, mùi thơm và vị ngọt dịu.', 20000, 30, 1, 5, 30, 'https://statics.vinpearl.com/xoi-xeo-01%20(2)_1632322118.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (4, N'Canh Chua','Canh Chua là một món canh truyền thống của Việt Nam, nổi tiếng với hương vị chua chua ngọt ngọt. Nước canh sánh mịn, có rau sống, cá và tôm, tạo nên một món canh đặc biệt, thích hợp cho bữa cơm gia đình.', 35000, 10, 1, 5, 20, 'https://i-giadinh.vnecdn.net/2023/04/25/Thanh-pham-1-1-7239-1682395675.jpg');


 -- Toys 

INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(1, 'LEGO Star Wars Millennium Falcon', 'An iconic LEGO model of the Millennium Falcon spaceship.', 149.99, 50, 1, 4.9, 10, ' https://khodochoitreem.com/80088-large_default/lego-75295-millennium-falcon-microfighter-tank-60068.jpg '), 
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(2, 'Hot Wheels Super Track', 'An exciting racetrack for Hot Wheels cars.', 29.99, 100, 1, 4.7, 15, ' https://images-na.ssl-images-amazon.com/images/I/81j3hfLNcJL.jpg '), 
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(3, 'Barbie Dreamhouse', 'A luxurious three-story Barbie house with many accessories.', 199.99, 20, 1, 4.8, 20, ' https://m.media-amazon.com/images/I/71PpuvUNQ4L._AC_SL1500_.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(4, 'Nerf Elite Blaster', 'A high-performance Nerf blaster for action-packed play.', 39.99, 80, 1, 4.5, 10, ' https://images-na.ssl-images-amazon.com/images/I/71ePN1TIO2L.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(5, 'Play-Doh Ultimate Fun Factory', 'A fun and creative Play-Doh set with multiple molds and tools.', 14.99, 150, 1, 4.4, 5, ' https://m.media-amazon.com/images/I/81FzW2lwtmS._AC_SL1500_.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(6, 'Fisher-Price Laugh & Learn Puppy', 'Interactive puppy that teaches numbers and letters.', 19.99, 100, 1, 4.6, 10, ' https://images-na.ssl-images-amazon.com/images/I/71M9jsP2KTL.jpg '), 
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(7, 'Puzzle 1000 Pieces - Nature Scenes', 'A challenging 1000-piece puzzle featuring beautiful nature landscapes.', 9.99, 200, 1, 4.7, 15, ‘https://m.media-amazon.com/images/I/81YahRl9CyL._AC_SL1500_.jpg '), 
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(8, 'Transformers Optimus Prime Action Figure', 'A detailed action figure of Optimus Prime that can transform.', 24.99, 60, 1, 4.5, 10, ' https://m.media-amazon.com/images/I/71uRENNFM4L._AC_SL1500_.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(9, 'Monopoly Classic Board Game', 'A timeless board game of buying, selling, and trading properties.', 19.99, 100, 1, 4.8, 12, ' https://images-na.ssl-images-amazon.com/images/I/61qODZoJc5L.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(10, 'UNO Card Game', 'A classic family card game that’s easy to learn and fun to play.', 7.99, 300, 1, 4.9, 5, ' https://m.media-amazon.com/images/I/81o2DARcdHL._AC_SL1500_.jpg '); 

-- Stationery 
 
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(1, 'Moleskine Classic Notebook', 'A high-quality, durable notebook perfect for journaling.', 19.99, 150, 1, 4.8, 10, ' https://images-na.ssl-images-amazon.com/images/I/81LPIiywLTL.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 
(2, 'Pilot G2 Gel Pen', 'A smooth-writing gel pen with a comfortable grip.', 2.99, 500, 1, 4.7, 5, ' https://images-na.ssl-images-amazon.com/images/I/7165rkMde2L.jpg '), 
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(3, 'Sticky Notes 3x3 Pack', 'A colorful pack of sticky notes perfect for reminders and notes.', 4.99, 400, 1, 4.6, 8, ' https://m.media-amazon.com/images/I/51gMy464JaL._AC_SL1250_.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(4, 'Staedtler Colored Pencils Set of 24', 'A vibrant set of colored pencils for art and design.', 12.99, 200, 1, 4.7, 12, ' https://m.media-amazon.com/images/I/71FkuGmJFKL._AC_SL1500_.jpg '), 
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(5, 'A4 Ring Binder Folder', 'A durable ring binder for organizing documents.', 6.99, 300, 1, 4.5, 10, ' https://images-na.ssl-images-amazon.com/images/I/81LPIiywLTL.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(6, 'Sharpie Fine Point Permanent Marker', 'A versatile permanent marker for labeling and creative projects.', 1.99, 500, 1, 4.8, 5, ' https://pos.nvncdn.com/0d884c-53121/ps/20220422_HLOLMUGw9YlJInuqYgLVQney.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(7, 'Elmer\'s Glue-All Multi-Purpose Glue', 'A reliable multi-purpose glue for crafts and projects.', 3.49, 250, 1, 4.6, 8, ' https://images-na.ssl-images-amazon.com/images/I/61q+x3tD8WL.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(8, 'Scotch Magic Tape Dispenser', 'An easy-to-use tape dispenser for office and home use.', 5.99, 150, 1, 4.7, 10, ' https://m.media-amazon.com/images/I/71Y2em1MtzL._AC_SL1500_.jpg '),
	
INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(9, 'Post-it Flag Highlighter', 'A highlighter with built-in Post-it flags for easy marking.', 3.99, 300, 1, 4.7, 8, ' https://m.media-amazon.com/images/I/71dAFbnucmL._AC_SL1500_.jpg '),

INSERT INTO Product (product_id, product_name, product_description, product_price, product_limit, product_status, product_rate, discount_percent, product_img_url) VALUES 	
(10, 'Faber-Castell Eraser Pencil', 'An eraser in pencil form for precise erasing.', 1.49, 400, 1, 4.6, 5, ' https://m.media-amazon.com/images/I/712rTU0O-iL._AC_SL1500_.jpg '); 
	

-- Health & Beauty
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'French Fries','Khoai tây chiên là một món ăn được làm từ khoai tây cắt thành những miếng dài và chiên trong dầu nóng. Khoai tây chiên có vị giòn bên ngoài và mềm bên trong, thường được ăn kèm với muối, tương cà hoặc sốt mayonnaise.', 25000, 30, 1, 5, 10, 'https://static.toiimg.com/thumb/54659021.cms?imgsize=275086&width=800&height=800');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Hot Dog','Hot Dog, hay còn gọi là xúc xích, là một món ăn vỉa hè nổi tiếng trên khắp thế giới. Nó gồm một cái ổ bánh mềm mịn và xúc xích thơm lừng, được thưởng thức trong những bữa ăn nhanh và dễ dàng ăn bằng tay.', 30000, 20, 1, 5, 0, 'https://i.redd.it/uke6xn3ji5071.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Nachos','Nachos tuyệt vời của chúng tôi là một tác phẩm nghệ thuật đầy màu sắc, với lớp phủ phô mai béo ngậy, ớt cay nồng, và những miếng bánh tortilla giòn tan.', 35000, 30, 1, 5, 0, 'https://www.simplyrecipes.com/thmb/xTCx1mKCjjPYgGasys_JGafuem0=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/__opt__aboutcom__coeus__resources__content_migration__simply_recipes__uploads__2019__04__Nachos-LEAD-3-e6dd6cbb61474c9889e1524b3796601e.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Pizza','Bánh pizza ngon tuyệt vời với lớp vỏ giòn, phủ đầy sốt cà chua thơm phức và phô mai béo ngậy. Tận hưởng hòa quyện hương vị từ những lớp nhân thịt và rau sống tươi ngon.', 40000, 30, 1, 5, 15, 'https://www.allrecipes.com/thmb/fFW1o307WSqFFYQ3-QXYVpnFj6E=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/48727-Mikes-homemade-pizza-DDMFS-beauty-4x3-BG-2974-a7a9842c14e34ca699f3b7d7143256cf.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Dumplings','Dumplings là loại món ngon có hình dáng giống như viên bi nhỏ. Chúng được làm từ bột và nhân thịt hoặc rau cải tươi mà bạn muốn. Hấp hoặc chiên cùng nước mắm chua ngọt, mmm ngon!', 35000, 20, 1, 5, 0, 'https://www.bhg.com/thmb/eQgTJ-Bl7DUSNIVQvfntHP3ZVOM=/2000x0/filters:no_upscale():strip_icc()/bhg-pork-and-shitake-steamed-dumplings-FmOg5-5J4gv94CccQYTVph-0ef0a4a8987244759154f9e5e1b1819e.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Fish and Chips','Fish and Chips là một món ăn phổ biến ở Anh, gồm cá chiên giòn và khoai tây chiên dài. Cá thường là cá tuyết hoặc cá ngừ, được tẩm bột và chiên trong dầu nóng. Khoai tây được cắt thành miếng dày và chiên giòn bên ngoài, mềm bên trong. Món ăn thường được ăn với muối, dấm, tương cà hoặc sốt tương.', 45000, 30, 1, 5, 5, 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/ff/Fish_and_chips_blackpool.jpg/800px-Fish_and_chips_blackpool.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Fried Calamari','Cá viên chiên giòn là một món ngon với sự pha trộn hoàn hảo giữa sò điệp tươi ngon và lớp bột chiên giòn giòn, tạo nên một trải nghiệm ẩm thực độc đáo và ngon miệng.', 38000, 20, 1, 5, 0, 'https://www.seriouseats.com/thmb/RLHQFr_lp9-HTIWBikzVwu4M17s=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/__opt__aboutcom__coeus__resources__content_migration__serious_eats__seriouseats.com__2020__11__20201125-fried-calamari-vicky-wasik-10-9cee3a081e96476b89e29b331d30be61.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Gnocchi','Gnocchi là một món ăn của Ý, được làm từ khoai tây, bột mì và trứng. Gnocchi có hình dạng nhỏ, tròn và xẹp, thường được nấu chín trong nước sôi và ăn kèm với sốt. Gnocchi có vị ngọt, mềm và bùi.', 32000, 3, 0, 5, 0, 'https://www.marthastewart.com/thmb/AdbLwcdFLpcsvW1bah2OuLij55o=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/336461-gnocchi-with-tomato-sauce-hero-04-1fe29843b76a4f0ab2ebc226de2723a0.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Hamburger','Bánh mì bò hấp dẫn với bánh mì mềm mịn và miếng bò xông khói thơm bốc. Một bữa ăn xịn sò, phủ nước sốt tuyệt vời!', 30000, 20, 1, 5, 10, 'https://www.washingtonpost.com/wp-apps/imrs.php?src=https://arc-anglerfish-washpost-prod-washpost.s3.amazonaws.com/public/M6HASPARCZHYNN4XTUYT7H6PTE.jpg&w=1440');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Huevos Rancheros','Huevos Rancheros là một món ăn sáng phổ biến ở Mexico, gồm trứng ốp la, sốt cà chua, đậu đen, pho mát và bánh ngô. Món ăn này đậm đà, bổ dưỡng và đầy màu sắc.', 35000, 30, 1, 5, 0, 'https://i0.wp.com/www.aspicyperspective.com/wp-content/uploads/2018/04/best-huevos-rancheros-recipe-25.jpg?resize=800%2C675&ssl=1');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (7, N'Tacos','Tacos là một món ăn truyền thống của Mexico, gồm một chiếc bánh mì dẹt mềm hoặc giòn, nhân thịt, rau, phô mai và sốt. Tacos có nhiều hương vị và cách ăn khác nhau, tùy vào sở thích của bạn.', 38000, 50, 1, 5, 15, 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/001_Tacos_de_carnitas%2C_carne_asada_y_al_pastor.jpg/1200px-001_Tacos_de_carnitas%2C_carne_asada_y_al_pastor.jpg');

-- Clothing
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Caprese Salad','Salad Caprese là một tác phẩm nghệ thuật ẩm thực từ Ý, với cà chua mọng nước, phô mai béo bùi, và lá bạch tuộc thơm mát. Một kết hợp độc đáo, như "bản giao hưởng" của mùa hè!', 35000, 20, 1, 5, 0, 'https://i2.wp.com/www.downshiftology.com/wp-content/uploads/2019/07/Caprese-Salad-main-1.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Greek Salad','Salát Hy Lạp là một món ăn nhẹ và tươi mát, gồm rau xanh, cà chua, dưa chuột, hành tím, ô liu đen và phô mai feta. Món salát được nêm với dầu ô liu, giấm và các loại gia vị như oregano và hạt tiêu.', 32000, 30, 1, 5, 10, 'https://cdn.loveandlemons.com/wp-content/uploads/2019/07/greek-salad-2.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Guacamole','Guacamole là một loại sốt xanh mướt, ngon ngọt từ bơ, cà chua, hành, ớt và một chút chanh. Ăn với bánh mì, bánh nachos hoặc salad.', 28000, 35, 1, 5, 0, 'https://www.giallozafferano.com/images/255-25549/Guacamole_1200x800.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Hummus','Hummus là món ăn ngon từ Trung Đông, được làm từ đậu nành mịn màng, hòa quyện cùng tỏi, dầu ô liu và gia vị. Nó có màu nâu nhạt và mùi thơm hấp dẫn.', 25000, 3, 0, 5, 0, 'https://i2.wp.com/www.downshiftology.com/wp-content/uploads/2022/08/Hummus-main-1.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Caesar Salad','Caesar Salad là một món salad ngon và bổ dưỡng, gồm rau xà lách, bánh mì nướng giòn, phô mai Parmesan và sốt Caesar đặc biệt. Bạn có thể thêm thịt gà, cá hoặc tôm để tăng hương vị. (29 words)', 30000, 50, 1, 5, 10, 'https://cdn.loveandlemons.com/wp-content/uploads/2019/12/caesar-salad-recipe.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Risotto','Món risotto là một món ăn Ý ngon lành, thơm ngậy và nhẹ nhàng, với hạt gạo mềm mịn, ăn kèm với các loại rau và gia vị tuyệt vời.', 38000, 40, 1, 5, 0, 'https://www.allrecipes.com/thmb/854efwMYEwilYjKr0FiF4FkwBvM=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/85389-gourmet-mushroom-risotto-DDMFS-4x3-a8a80a8deb064c6a8f15452b808a0258.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Omelette','Omelette là một món ăn được làm từ trứng gà đánh đều, rán chín trên chảo, có thể thêm pho mát, thịt, rau hoặc gia vị tùy ý. Omelette có hình dạng tròn, mềm và thơm ngon.', 26000, 30, 1, 5, 0, 'https://realfood.tesco.com/media/images/1400x919-Tesco-5For15-13273-RainbowOmelette-b3f0c3cc-2f15-40a7-98b1-07af0609f99e-0-1400x919.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Onion Rings','Các chiếc miếng cơm hành được cắt mỏng, chặt vàng giòn từ hành, bọc trong lớp vỏ ngoài giòn tan.', 22000, 20, 1, 5, 15, 'https://th.bing.com/th/id/OIG.tUsUxbWy2qtAgqLtbaxx?pid=ImgGn');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Poutine','Poutine là một món ăn ngon của Canada gồm khoai tây chiên giòn, phủ lớp phô mai nóng béo và sốt ngon tuyệt. Một món ăn đơn giản nhưng vô cùng ngon miệng.', 25000, 30, 1, 5, 0, 'https://www.seasonsandsuppers.ca/wp-content/uploads/2014/01/new-poutine-1.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Club Sandwich','Bánh mì kẹp Club - một tác phẩm nghệ thuật ẩm thực với lớp mỡ tươi ngon, thịt gà thơm lừng, trứng luộc bổ dưỡng và rau sống tươi mát. Hãy thưởng thức hương vị tuyệt vời này!', 35000, 25, 1, 5, 0, 'https://www.foodandwine.com/thmb/tM060YA0Fd0UALCmPQ-5gGWyBqA=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/Classic-Club-Sandwich-FT-RECIPE0523-99327c9c87214026b9419b949ee13a9c.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Beet Salad','Salad củ dền tươi ngon, cắt nhỏ với hạt óc chó và phô mai feta, chấm với sốt dầu ôliu và chanh.', 28000, 30, 1, 5, 5, 'https://cdn.loveandlemons.com/wp-content/uploads/2021/11/beet-salad-1.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Cheese Plate','Dĩa Phô Mai - Một dĩa gồm nhiều loại phô mai ngon, béo, mềm mịn kết hợp với bánh mì giòn tan và những thành phần khác giúp kích thích vị giác của bạn.', 32000, 50, 0, 5, 5, 'https://www.barleyandsage.com/wp-content/uploads/2021/08/summer-cheeseboard-1200x1200-1.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Clam Chowder','Clam Chowder là một món súp béo ngậy với nhiều sò huyết, khoai tây, cà rốt và hành tây. Món này có vị ngọt của sò, mặn của nước biển và thơm của kem. Clam Chowder thường được ăn với bánh mì nướng hoặc bánh quy bơ.', 26000, 10, 1, 5, 0, 'https://s23209.pcdn.co/wp-content/uploads/2019/10/Easy-Clam-ChowderIMG_1064.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Croque Madame','Croque Madame là một món ăn đơn giản nhưng ngon miệng, gồm một lát bánh mì nướng, phủ phô mai và thịt nguội, và một quả trứng ốp la trên đỉnh. Bạn có thể ăn nó với salad hoặc khoai tây chiên.', 32000, 20, 0, 5, 5, 'https://hips.hearstapps.com/hmg-prod/images/190417-croque-monsieur-horizontal-476-1556565130.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Edamame','Edamame là món đậu gốc Đông Á, rất phổ biến trong ẩm thực Nhật Bản. Nhìn qua, nó giống như những trái đậu nhỏ xinh, màu xanh bóng. Ăn vào sẽ cảm nhận được vị ngọt tự nhiên và nhẹ nhàng, rất thích hợp để ăn kèm với các món khác.', 18000, 30, 1, 5, 0, 'https://peasandcrayons.com/wp-content/uploads/2018/02/quick-easy-spicy-sambal-edamame-recipe-2.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Eggs Benedict','Trứng Benedict là một món ăn ngon giòn và lạ miệng, với trứng chần ở trên lớp thịt mềm, béo ngậy. Món này tuyệt để bắt đầu một ngày tuyệt vời!', 32000, 20, 1, 5, 15, 'https://www.foodandwine.com/thmb/j6Ak6jECu0fdly1XFHsp4zZM8gQ=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/Eggs-Benedict-FT-RECIPE0123-4f5f2f2544464dc89a667b5d960603b4.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Foie Gras','Foie Gras là một món ăn được làm từ gan ngỗng hoặc vịt đã được nuôi đặc biệt. Gan có màu vàng nhạt, mềm và béo. Foie Gras có thể được nướng, hấp, chiên hoặc làm mứt. Món ăn có vị ngọt, béo và thơm.', 75000, 15, 1, 5, 0, 'https://upload.wikimedia.org/wikipedia/commons/8/82/Foie_gras_en_cocotte.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Grilled Cheese Sandwich','Bánh sandwich pho mát nướng là món ăn ngon miệng có kết cấu mềm mịn, hấp dẫn với lớp pho mát tan chảy bên trong và bề mặt giòn tan.', 25000, 20, 1, 5, 20, 'https://static01.nyt.com/images/2023/02/28/multimedia/ep-air-fryer-grilled-cheese-vpmf/ep-air-fryer-grilled-cheese-vpmf-mediumSquareAt3X.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Ice Cream','Kem là một món tráng miệng thơm ngon và lạ miệng, với hương vị ngọt ngào và mịn màng của kem được làm từ sữa và đá, cùng với nhiều loại topping thích hợp cho mọi sở thích.', 15000, 50, 0, 5, 0, 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aWNlX2NyZWFtfGVufDB8fDB8fHww&w=1000&q=80');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Paella','Paella là một món ăn Tây Ban Nha hấp dẫn gồm nhiều thành phần như cơm, tôm, cá, gà và các loại rau. Hương vị đậm đà, màu sắc bắt mắt, rất ngon miệng.', 42000, 10, 1, 5, 0, 'https://www.allrecipes.com/thmb/PdwNPwZiNXr9cw8W6WQacCl6i98=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/84137-easy-paella-DDMFS-4x3-08712e61e7dc453d94673f65f9eca7d2.jpg');
insert into Product (product_type_id, product_name, product_description, product_price, product_limit, product_status, discount_price, product_img_url)    
VALUES (8, N'Waffles','Waffles là một loại bánh ngọt xốp, giòn, nóng hổi với hình dáng lưới hoặc ô vuông. Thường được ăn với siro, kem và hoa quả.', 18000, 20, 0, 5, 15, 'https://www.allrecipes.com/thmb/imrP1HYi5pu7j1en1_TI-Kcnzt4=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/20513-classic-waffles-mfs-025-4x3-81c0f0ace44d480ca69dd5f2c949731a.jpg');

-- Payment methods
insert into PaymentMethod (payment_method) values (N'Credit card');
insert into PaymentMethod (payment_method) values (N'Debit card');
insert into PaymentMethod (payment_method) values (N'COD');

-- Order statuses
insert into OrderStatus (order_status) values (N'Waiting');
insert into OrderStatus (order_status) values (N'Preparing');
insert into OrderStatus (order_status) values (N'In progress');
insert into OrderStatus (order_status) values (N'Delivered');
insert into OrderStatus (order_status) values (N'Canceled');

-- Voucher
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Quốc tế phụ nữ', 'ADASD2FD23123DBE', 30, 15, 0,'20231021 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng may mắn', 'BD2128BDYOQM87V7', 20, 10, 0,'20230809 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Halloween cùng FFood', 'XDEF39O9YOQM8PPV', 15, 20, 0,'20231101 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Người đặc biệt', 'DJWOA975N4B92BH6', 50, 3, 1,'20231112 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Ngày Nhà giáo Việt Nam', '9JADYEDYOQM8E7OA', 15, 10, 0,'20231121 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values (N'Quà tặng Noel', 'DUEMAHWOPUNH62GH', 20, 10, 1,'20231223 00:01:00 AM' );

-- Cart, CartItem, Order test data
insert into Cart (customer_id) values (1);

insert into CartItem (cart_id, product_id, product_price, product_quantity) values (1, 2, 50000, 2);
insert into CartItem (cart_id, product_id, product_price, product_quantity) values (1, 10, 30000, 1);
insert into CartItem (cart_id, product_id, product_price, product_quantity) values (1, 23, 20000, 3);

-- Insert an Order for the Cart
insert into [Order] (
cart_id, customer_id ,order_status_id, payment_method_id,
contact_phone, delivery_address, order_time, order_total, 
order_note, delivery_time, order_cancel_time
) values (
1, 1, 4, 1, 
'0931278397', N'39 Mậu Thân, Ninh Kiều, Cần Thơ', '20231108 10:49:00 AM', 190000, 
NULL, '20231108 10:49:00 AM', NULL);

insert into Payment (
    order_id, payment_method_id, payment_total, payment_content, payment_bank, payment_code, payment_status, payment_time
) values (
    1,1,190000,N'Thanh toán đơn hàng ffood',N'NCB','14111641',1,'20231108 11:20:00 AM'
);

update Account set lastime_order = '20231108 10:34:00 AM' where account_id = 201

insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 1, N'Cập nhật thông tin đơn hàngg','20231108 10:51:00 AM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 1, N'Cập nhật trạng thái đơn hàng','20231108 11:03:00 AM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 2, N'Cập nhật trạng thái đơn hàng','20231108 11:18:00 AM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 3, N'Cập nhật trạng thái đơn hàng','20231108 11:20:00 AM');

-- Cart, CartItem, Order test data
insert into Cart (customer_id) values (2);

insert into CartItem (cart_id, product_id, product_price, product_quantity) values (2, 5, 40000, 2);
insert into CartItem (cart_id, product_id, product_price, product_quantity) values (2, 14, 25000, 3);
insert into CartItem (cart_id, product_id, product_price, product_quantity) values (2, 23, 20000, 3);

-- Insert an Order for the Cart
insert into [Order] (
cart_id, customer_id ,order_status_id, payment_method_id,
contact_phone, delivery_address, order_time, order_total, 
order_note, delivery_time, order_cancel_time
) values (
2, 5, 4, 3, 
'0931278397', N'39 Mậu Thân, Ninh Kiều, Cần Thơ', '20231108 15:43:00 PM', 215000, 
NULL, '20231108 15:43:00 PM', NULL);

update Account set lastime_order = '20231108 15:43:00 PM' where account_id = 205

insert into OrderLog (order_id, staff_id, log_activity, log_time) values (2, 1, N'Cập nhật trạng thái đơn hàng','20231108 15:50:00 PM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (2, 2, N'Cập nhật trạng thái đơn hàng','20231108 16:05:00 PM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (2, 3, N'Cập nhật trạng thái đơn hàng','20231108 16:20:00 PM');

