/* =====================================================
   وظيفة Advanced SQL Programming - شركة صحتك للأدوية
   ملاحظة: أنشئ المجلد C:\SQLData قبل التنفيذ
   ===================================================== */

/* ---------- 1.1 إنشاء القاعدة وملفاتها ----------
   التعليل:
   - ملف البيانات (.mdf): يخزن الجداول والفهارس. حجمه الابتدائي 50MB لأن الشركة
     تسجل طلبات وتفاصيل كثيرة مع الوقت، ونموه 10MB ثابت لتفادي التوسع المفاجئ.
   - ملف السجل (.ldf): يسجل العمليات للتعافي من الأعطال. حجمه أصغر (20MB)
     لأنه يخزن العمليات لا البيانات نفسها.
   - MAXSIZE يمنع امتلاء القرص بالكامل.
   ------------------------------------------------ */
CREATE DATABASE SihhatakDB
ON PRIMARY (
    NAME = SihhatakDB_Data,
    FILENAME = 'C:\SQLData\SihhatakDB.mdf',
    SIZE = 50MB, MAXSIZE = 500MB, FILEGROWTH = 10MB
)
LOG ON (
    NAME = SihhatakDB_Log,
    FILENAME = 'C:\SQLData\SihhatakDB_log.ldf',
    SIZE = 20MB, MAXSIZE = 200MB, FILEGROWTH = 10MB
);
GO
USE SihhatakDB;
GO

/* ---------- 1.2 إنشاء الجداول (الأنماط مع التعليل) ----------
   - المعرفات INT IDENTITY: أرقام تلقائية فريدة وصغيرة وسريعة بالربط.
   - الأسماء NVARCHAR: لدعم العربية.
   - الأسعار والمبالغ DECIMAL(12,2): دقة مالية دون أخطاء التقريب في FLOAT.
   - التواريخ DATE/DATETIME: لدعم الفرز والمقارنة الزمنية.
   - Status VARCHAR(20): قيم نصية قصيرة محددة.
   - LineTotal: حقل محسوب (الكمية × السعر) لمنع التناقض.
   ------------------------------------------------------- */
CREATE TABLE Customers (
    CustomerID       INT IDENTITY(1,1) NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    Phone            VARCHAR(20)   NOT NULL,
    City             NVARCHAR(50)  NOT NULL,
    Address          NVARCHAR(200) NULL,
    RegistrationDate DATE          NOT NULL,
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerID)
);

CREATE TABLE Categories (
    CategoryID   INT IDENTITY(1,1) NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    Description  NVARCHAR(300) NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID)
);

CREATE TABLE Products (
    ProductID   INT IDENTITY(1,1) NOT NULL,
    ProductName NVARCHAR(150) NOT NULL,
    CategoryID  INT           NOT NULL,
    UnitPrice   DECIMAL(12,2) NOT NULL,
    StockQty    INT           NOT NULL,
    CONSTRAINT PK_Products PRIMARY KEY (ProductID)
);

CREATE TABLE Orders (
    OrderID     INT IDENTITY(1,1) NOT NULL,
    CustomerID  INT           NOT NULL,
    OrderDate   DATE          NOT NULL,
    TotalAmount DECIMAL(14,2) NOT NULL,
    Status      VARCHAR(20)   NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID)
);

CREATE TABLE OrderDetails (
    DetailID  INT IDENTITY(1,1) NOT NULL,
    OrderID   INT           NOT NULL,
    ProductID INT           NOT NULL,
    Quantity  INT           NOT NULL,
    UnitPrice DECIMAL(12,2) NOT NULL,
    LineTotal AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT PK_OrderDetails PRIMARY KEY (DetailID)
);
GO

/* ---------- 1.3 القيود ----------
   التعليل: PK لتمييز كل سجل، FK لسلامة العلاقات (لا طلب بلا عميل ولا منتج بلا فئة)،
   CHECK لمنع قيم غير منطقية (سعر سالب، كمية صفر)، DEFAULT لتعبئة تلقائية،
   UNIQUE لمنع تكرار رقم الهاتف واسم الفئة.
   ---------------------------------------------------- */
ALTER TABLE Customers  ADD CONSTRAINT UQ_Customers_Phone      UNIQUE (Phone);
ALTER TABLE Customers  ADD CONSTRAINT DF_Customers_RegDate    DEFAULT (CAST(GETDATE() AS DATE)) FOR RegistrationDate;
ALTER TABLE Categories ADD CONSTRAINT UQ_Categories_Name      UNIQUE (CategoryName);

ALTER TABLE Products ADD CONSTRAINT FK_Products_Categories
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID);
ALTER TABLE Products ADD CONSTRAINT CK_Products_UnitPrice CHECK (UnitPrice > 0);
ALTER TABLE Products ADD CONSTRAINT CK_Products_StockQty  CHECK (StockQty >= 0);
ALTER TABLE Products ADD CONSTRAINT DF_Products_StockQty  DEFAULT (0) FOR StockQty;

ALTER TABLE Orders ADD CONSTRAINT FK_Orders_Customers
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);
ALTER TABLE Orders ADD CONSTRAINT CK_Orders_Status
    CHECK (Status IN ('Pending','Shipped','Delivered','Canceled'));
ALTER TABLE Orders ADD CONSTRAINT CK_Orders_Total  CHECK (TotalAmount >= 0);
ALTER TABLE Orders ADD CONSTRAINT DF_Orders_Date   DEFAULT (CAST(GETDATE() AS DATE)) FOR OrderDate;
ALTER TABLE Orders ADD CONSTRAINT DF_Orders_Status DEFAULT ('Pending') FOR Status;
ALTER TABLE Orders ADD CONSTRAINT DF_Orders_Total  DEFAULT (0) FOR TotalAmount;

ALTER TABLE OrderDetails ADD CONSTRAINT FK_OD_Orders
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID);
ALTER TABLE OrderDetails ADD CONSTRAINT FK_OD_Products
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID);
ALTER TABLE OrderDetails ADD CONSTRAINT CK_OD_Quantity  CHECK (Quantity > 0);
ALTER TABLE OrderDetails ADD CONSTRAINT CK_OD_UnitPrice CHECK (UnitPrice > 0);
GO

/* ---------- 1.4 الفهارس ----------
   التعليل: المفاتيح الأساسية تنشئ فهرساً عنقودياً تلقائياً.
   نضيف فهارس غير عنقودية على أعمدة المفاتيح الخارجية لأنها تُستخدم دائماً
   في الربط JOIN، وعلى City لأنها تُستخدم في التجميع والبحث.
   ------------------------------------------------ */
CREATE NONCLUSTERED INDEX IX_Products_CategoryID    ON Products(CategoryID);
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID      ON Orders(CustomerID);
CREATE NONCLUSTERED INDEX IX_OrderDetails_OrderID   ON OrderDetails(OrderID);
CREATE NONCLUSTERED INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);
CREATE NONCLUSTERED INDEX IX_Customers_City         ON Customers(City);
GO

/* ---------- 1.5 إدخال البيانات ----------
   استبدل أسماء العملاء بأسماء الطلاب المشاركين في الوظيفة */
INSERT INTO Customers (FirstName, LastName, Phone, City, Address, RegistrationDate) VALUES
(N'طالب1', N'الأول',   '0911111111', N'دمشق',  N'المزة',        '2026-01-10'),
(N'طالب2', N'الثاني',  '0922222222', N'دمشق',  N'كفرسوسة',      '2026-02-05'),
(N'طالب3', N'الثالث',  '0933333333', N'حلب',   N'الفرقان',      '2026-02-20'),
(N'طالب4', N'الرابع',  '0944444444', N'حلب',   N'الجميلية',     '2026-03-15'),
(N'طالب5', N'الخامس',  '0955555555', N'حمص',   N'الوعر',        '2026-04-01'),
(N'طالب6', N'السادس',  '0966666666', N'اللاذقية', N'الزراعة',   '2026-05-12'),
(N'طالب7', N'السابع',  '0977777777', N'حمص',   N'الخالدية',     '2026-06-18'),
(N'طالب8', N'الثامن',  '0988888888', N'دمشق',  N'المالكي',      '2026-07-22');

INSERT INTO Categories (CategoryName, Description) VALUES
(N'أدوية عامة',    N'مسكنات ومضادات حيوية شائعة'),
(N'أدوية مزمنة',   N'أدوية السكري والضغط والقلب'),
(N'مستلزمات طبية', N'أجهزة قياس ومستهلكات طبية'),
(N'عناية شخصية',   N'منتجات العناية بالبشرة والشعر والأسنان'),
(N'فيتامينات',     N'مكملات غذائية وفيتامينات'),
(N'أجهزة طبية',    N'أجهزة طبية كبيرة (لا منتجات بها حالياً)');

INSERT INTO Products (ProductName, CategoryID, UnitPrice, StockQty) VALUES
(N'بنادول',               1,   5000, 100),
(N'أموكسيسيلين',          1,  12000,   0),
(N'ميتفورمين',            2,  18000,  60),
(N'أملوديبين',            2,  22000,   0),
(N'جهاز قياس ضغط',        3, 150000,  15),
(N'جهاز قياس سكر',        3,  90000,  20),
(N'علبة كمامات',          3,  12000, 200),
(N'شامبو طبي',            4,  35000,  40),
(N'معجون أسنان',          4,  15000,  80),
(N'واقي شمس',             4,  60000,  25),
(N'فيتامين C',            5,  25000,  70),
(N'أوميغا 3',             5,  45000,  30);

INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status) VALUES
(1,'2026-09-01',0,'Delivered'),(1,'2026-09-10',0,'Delivered'),(1,'2026-09-20',0,'Shipped'),
(2,'2026-09-02',0,'Delivered'),(2,'2026-09-12',0,'Pending'),  (2,'2026-09-25',0,'Delivered'),
(3,'2026-09-05',0,'Delivered'),(3,'2026-09-15',0,'Canceled'),
(4,'2026-09-08',0,'Delivered'),
(5,'2026-09-18',0,'Shipped'),
(6,'2026-09-22',0,'Delivered'),
(7,'2026-10-01',0,'Pending');

-- (OrderID, ProductID, Quantity, UnitPrice)
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(1,5,1,150000),(1,1,3,5000),
(2,8,2,35000),(2,11,1,25000),
(3,2,2,12000),
(4,6,1,90000),(4,9,2,15000),
(5,3,2,18000),
(6,10,1,60000),(6,7,5,12000),
(7,4,1,22000),(7,1,2,5000),
(8,11,1,25000),
(9,12,2,45000),(9,8,1,35000),
(10,7,3,12000),
(11,9,1,15000),(11,1,1,5000),
(12,3,1,18000),(12,1,1,5000);

-- تحديث إجمالي كل طلب من تفاصيله لضمان الاتساق
UPDATE o
SET TotalAmount = d.Total
FROM Orders o
JOIN (SELECT OrderID, SUM(LineTotal) AS Total FROM OrderDetails GROUP BY OrderID) d
  ON d.OrderID = o.OrderID;
GO

/* ===================== 2. الاستعلامات ===================== */

-- 2.1 العملاء الذين لديهم أكثر من طلبين
SELECT c.CustomerID,
       c.FirstName + N' ' + c.LastName AS FullName,
       COUNT(o.OrderID) AS OrdersCount
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(o.OrderID) > 2;

-- 2.2 جميع الفئات وعدد منتجاتها (مع الفئات الفارغة): LEFT JOIN
SELECT c.CategoryName,
       COUNT(p.ProductID) AS ProductsCount
FROM Categories c
LEFT JOIN Products p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName;

-- 2.3 منتجات "مستلزمات طبية" الأعلى سعراً من أعلى منتج في "عناية شخصية"
SELECT p.ProductName, p.UnitPrice
FROM Products p
JOIN Categories c ON c.CategoryID = p.CategoryID
WHERE c.CategoryName = N'مستلزمات طبية'
  AND p.UnitPrice > (
        SELECT MAX(p2.UnitPrice)
        FROM Products p2
        JOIN Categories c2 ON c2.CategoryID = p2.CategoryID
        WHERE c2.CategoryName = N'عناية شخصية');

-- 2.4 العملاء (الاسم الكامل والمدينة) الذين اشتروا منتجات نفذت من المخزن
SELECT DISTINCT
       c.FirstName + N' ' + c.LastName AS FullName,
       c.City
FROM Customers c
JOIN Orders o        ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON od.OrderID   = o.OrderID
JOIN Products p      ON p.ProductID  = od.ProductID
WHERE p.StockQty = 0;

-- 2.5 المدن التي يتجاوز متوسط قيمة الطلبات فيها 30000 ل.س
SELECT c.City,
       AVG(o.TotalAmount) AS AvgOrderValue
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.City
HAVING AVG(o.TotalAmount) > 30000;
