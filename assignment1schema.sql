DROP TABLE IF EXISTS
    Category, 
    isCategoryOf, 
    Products, 
    Manufacturer, 
    Manufactured, 
    Countries, 
    Shops, 
    Sells, 
    Orders, 
    OrderItem, 
    Employees, 
    Users, 
    MakeComments, 
    Comments, 
    ReplyTo, 
    Rates, 
    Complaints, 
    handleComplaints, 
    RefundRequests, 
    MakeRates,
    MakeRefundRequest, 
    HandleRefundRequest,
    Coupons, 
    ApplyCoupon, 
    Hosted
CASCADE;

CREATE TABLE Countries (
    CountryId                       INTEGER PRIMARY KEY,
    CountryName                     TEXT NOT NULL
); 

/*
    Table exists so that the Country input into Products Table can be verified against.
*/

CREATE TABLE Employees(
	Eid			                    INTEGER PRIMARY KEY,
	Ename			                TEXT,
	monthlySalary 	                NUMERIC(10,2)
);

CREATE TABLE Users (
	Uid			                    INTEGER PRIMARY KEY,
	Uname			                TEXT,
	Uaddress		                TEXT
);

CREATE TABLE Category (
	Cid			                    INTEGER PRIMARY KEY,
	Cname			                TEXT NOT NULL
);

CREATE TABLE Shops (
	Sid 			                INTEGER PRIMARY KEY,
	Sname			                TEXT NOT NULL
);

CREATE TABLE Manufacturer (
	Mid			                    INTEGER PRIMARY KEY,
	Mname		                    TEXT NOT NULL,
	CountryId                       INTEGER REFERENCES Countries(CountryId)
);


CREATE TABLE Products (
	Pid			                    INTEGER PRIMARY KEY,
	Pname			                TEXT NOT NULL,
	Cid 		                    INTEGER REFERENCES Category(Cid),
	Mid 			                INTEGER REFERENCES Manufacturer(Mid),
    Description 		            TEXT,
    Price 			                NUMERIC(10,2) NOT NULL,
    QtyLeft		                    INTEGER DEFAULT 0
-- QTY shouldnt be here I think, qty indicates the availability in shop so I will put in Sells
-- Not sure if Price/description/Mid should be in Sells too….
);



CREATE TABLE Manufactured (
	Pid			                    INTEGER REFERENCES Products(Pid) NOT NULL,
	Mid			                    INTEGER REFERENCES Manufacturer(Mid) NOT NULL,
	PRIMARY KEY (pid, mid)
);

-- Might need another table to show the 2 roles in relationships , using categorizedAs or something

CREATE TABLE isCategoryOf (
	ParentCid			            INTEGER REFERENCES Category(Cid) NOT NULL, 
	ChildPid 			            INTEGER REFERENCES Products(Pid), 
	ChildCid 		                INTEGER REFERENCES Category(Cid),
    /*
        Choice of PRIMARY KEY is because a parent category must exist for each relation instance, but being the parent of a child
        category or a child product is mutually exclusive and therefore there may be null values under either of the two attributes for some instances.
    */ 
	PRIMARY KEY (ParentCid),
	CONSTRAINT childIdNotParentId CHECK (ChildCid <> ParentCid)
);

/*
    Table exists to store general sales-related information.
*/
CREATE TABLE Sells (
	Sid			                    INTEGER REFERENCES Shops(Sid) NOT NULL,
	Pid			                    INTEGER REFERENCES Products(Pid) NOT NULL,

	PRIMARY KEY (sid, pid)
);

CREATE TABLE Orders (
	OrderId			                INTEGER PRIMARY KEY,
	TotalCost		                NUMERIC(10,2) DEFAULT 0,

    ShippingCost		            NUMERIC(10,2),
    ShippingAddress	                TEXT
);

CREATE TABLE Coupons(
    CouponId                        INTEGER PRIMARY KEY,
    Uid                             INTEGER REFERENCES Users(Uid),
    IssueDate                       DATE,
    ExpiryDate                      DATE,
    CouponReward                    NUMERIC(10, 2)

); 

CREATE TABLE ApplyCoupon (
    Uid                             INTEGER REFERENCES Users(Uid),
    CouponId                        INTEGER REFERENCES Coupons(CouponId),
    OrderId                         INTEGER REFERENCES Orders(OrderId)
);

-- //included is for each item in the order i think -matthew
CREATE TABLE OrderItem (
	Sid			                    INTEGER REFERENCES Shops(Sid),
	Pid			                    INTEGER REFERENCES Products(Pid),
	OrderId			                INTEGER REFERENCES Orders(OrderId),
    QtyOrdered                      INTEGER,

    estimatedDeliveryDate           DATE,
    ActualDeliveryDate              DATE,
    orderStatus                     TEXT,
	deliveredStatus		            TEXT,
    receivedStatus                  TEXT,

    /*
        Reason for this constraint is to check whether there is a
    */
    CONSTRAINT OrderItem_validDeliveredStatus check (
        deliveredStatus in ('delivered', 'pending')
        ),
    CONSTRAINT OrderItem_validReceivedStatus check (
        receivedStatus in ('received', 'pending')
        ),
    CONSTRAINT OrdersStatus_validDeliveredStatus check (
        deliveredStatus in ('being processed', 'shipped', 'delivered')
        ),
    PRIMARY KEY (Sid, Pid, orderId),
    FOREIGN KEY (Sid, Pid) REFERENCES Sells(Sid, Pid)
        ON DELETE CASCADE
);

CREATE TABLE RefundRequests(
	RefundId		                INTEGER PRIMARY KEY,
    OrderId                         INTEGER REFERENCES Orders(OrderId),
    Sid                             INTEGER REFERENCES Shops(Sid),
    Pid                             INTEGER REFERENCES Products(Pid),
    
    QtyToRefund                     INTEGER,
    
    RefundRequestDate               DATE,
    RefundAcceptDate                DATE,
    RefundRejectDate                DATE,
    ActualDeliveryDate              DATE,

    RejectReason                    TEXT,
    RefundStatus                    TEXT,
    RefundAmount                    NUMERIC(10, 2),

    FOREIGN KEY(OrderId, Sid, Pid) REFERENCES OrderItem
        ON DELETE CASCADE,
    CONSTRAINT validRefundStatus CHECK (RefundStatus IN ('Accepted', 'Rejected')),
    CONSTRAINT refundDateWithin30DaysAfterDeliveryDate CHECK(
        RefundRequestDate < ActualDeliveryDate + interval '30 days' AND
        RefundRequestDate >= ActualDeliveryDate
    )
    -- reject date may be null. can we still add a constraiint
);

CREATE TABLE MakeRefundRequest(
    Uid                             INTEGER REFERENCES Users(Uid),
    RefundId                        INTEGER REFERENCES RefundRequests(RefundId),
    PRIMARY KEY (UID, RefundId)
);

CREATE TABLE HandleRefundRequest(
    HandlingEmployeeEid                             INTEGER REFERENCES Employees(Eid),
    RefundId                        INTEGER REFERENCES RefundRequests(RefundId),
    -- Ensure only one employee handles each refund.
    PRIMARY KEY(HandlingEmployeeEid, RefundId)
);

-- ???? combine with something?

CREATE TABLE Comments(
	CommentId 		                INTEGER PRIMARY KEY,
	CommentTEXT                     TEXT,    
    OrderId                         INTEGER REFERENCES Orders(OrderId),
    Sid                             INTEGER REFERENCES Shops(Sid),
    Pid                             INTEGER REFERENCES Products(Pid),

    FOREIGN KEY(OrderId, Sid, Pid) REFERENCES OrderItem
	-- it has to be connected to the productID but it is only connected to OrderID
	-- Does this mean we need to connect to involved?
);

CREATE TABLE MakeComments(
    Uid                             INTEGER DEFAULT -1,
                                    -- References to Deleted User
    CommentId                       INTEGER REFERENCES Comments(CommentId),
    PRIMARY KEY (CommentId),
    -- Ensure Users defaults to "Deleted User" when deleted
    FOREIGN KEY (Uid) REFERENCES Users(Uid) ON DELETE SET DEFAULT
); 

CREATE TABLE ReplyTo(
	CommentingCommentid		        INTEGER REFERENCES Comments(Commentid), 
	-- ????? it has to be connected to the productID but it is only connected to OrderID
	-- Does this mean we need to connect to involved?
	RecipientCommentid 	            INTEGER REFERENCES Comments(Commentid),
    CommentingUid                   INTEGER REFERENCES Users,
    RecipientUid                    INTEGER REFERENCES Users,
	PRIMARY KEY (CommentingCommentid),
    CONSTRAINT replyNotSameUsers CHECK(CommentingUid <> RecipientUid)
);

CREATE TABLE Rates(
	RateId		                    INTEGER PRIMARY KEY,
	Rating 		                    INTEGER CHECK (Rating >= 1 and Rating <= 5),
    OrderId                         INTEGER REFERENCES Orders(OrderId),
    Sid                             INTEGER REFERENCES Shops(Sid),
    Pid                             INTEGER REFERENCES Products(Pid),
    FOREIGN KEY(OrderId, Sid, Pid) REFERENCES OrderItem
	-- ????? it has to be connected to the productID but it is only connected to OrderID
	-- Does this mean we need to connect to involved?
	
);

CREATE TABLE MakeRates(
    Uid                             INTEGER DEFAULT -1,
                                    -- References to Deleted User
    RateId                          INTEGER REFERENCES Rates(RateId),
    PRIMARY KEY (RateId),
    -- Ensure Users defaults to "Deleted User" when deleted
    FOREIGN KEY (Uid) REFERENCES Users(Uid) ON DELETE SET DEFAULT
); 

CREATE TABLE Complaints(
	Complaintid 		            INTEGER PRIMARY KEY,
    ComplaintText                   TEXT
    -- #PRIMARY KEY cant be (orderid, commentid, productid, sid etc ) because the complaint might only refer to 1 of them
    -- //todo default pending, then can being processed / addressed,
	
	-- # add foreign keys
	
);

CREATE TABLE handleComplaints(
    HandlingEmployeeEid             INTEGER REFERENCES Employees(Eid),
    ComplaintId                     INTEGER REFERENCES Complaints(ComplaintId),
	ComplaintStatus                 TEXT,
    PRIMARY KEY (HandlingEmployeeEid, ComplaintId),
    CONSTRAINT validComplaintStatus CHECK (ComplaintStatus IN ('Pending', 'Being processed', 'Addressed'))
); 

-- can this be combined into complains(we might wanna rename to complaints) or combined to employee?




-- We need to fix the ERD first



-- We need to fix ERD first

CREATE TABLE Hosted (
    Pid                             INTEGER REFERENCES Products(Pid),
    Sid                             INTEGER REFERENCES Shops(Sid),
    PRIMARY KEY(Pid, Sid)
);

-- ?? do we need this? Can we just disconnect shops and orders and make it go through sells or mix into shop /orders

-- CREATE TABLE MakeOrder(

-- ) ;
-- also not sure if we need, maybe mix into users/order tables






