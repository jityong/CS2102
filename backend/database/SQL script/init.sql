DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS Food CASCADE;
DROP TABLE IF EXISTS Sells CASCADE;
DROP TABLE IF EXISTS Restaurant_Staff CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Riders CASCADE;
DROP TABLE IF EXISTS Part_Time CASCADE;
DROP TABLE IF EXISTS Full_Time CASCADE;
DROP TABLE IF EXISTS Schedules CASCADE;
DROP TABLE IF EXISTS Monthly_Work_Schedules CASCADE;
DROP TABLE IF EXISTS Weekly_Work_Schedules CASCADE;
DROP TABLE IF EXISTS Intervals CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Order_Details CASCADE;
DROP TABLE IF EXISTS Schedules CASCADE;
DROP TABLE IF EXISTS Delivery_Details CASCADE;
DROP TABLE IF EXISTS Promotions CASCADE;
DROP TABLE IF EXISTS MinSpendingPromotions CASCADE;
DROP TABLE IF EXISTS CustomerPromotions CASCADE;

CREATE TABLE Users (
	userId 		SERIAL,
	name		VARCHAR(100),
    	PRIMARY KEY (userId)
);

CREATE TABLE Restaurants (
	rname 		VARCHAR(200),
	minOrderAmt	NUMERIC(8, 2),
	area 		VARCHAR(200),
    PRIMARY KEY (rname),
	CHECK(area = 'central' OR
		 area = 'west' OR
		 area = 'east' OR
		 area = 'north' OR
		 area = 'south')
);

CREATE TABLE Food (
	fname 		VARCHAR(20),
	category 	VARCHAR(20) NOT NULL,
    PRIMARY KEY (fname),
	CHECK (category = 'western' OR
		   category = 'chinese' OR
		   category = 'japanese' OR
		   category = 'korean' OR
		   category = 'fusion')
);

CREATE TABLE Sells (
	rname 		VARCHAR(20) REFERENCES Restaurants on DELETE CASCADE on UPDATE CASCADE,
    fname 		VARCHAR(20) REFERENCES Food on DELETE CASCADE on UPDATE CASCADE,
    price 		NUMERIC(8, 2) NOT NULL,
    availability 	INTEGER DEFAULT 10,
    PRIMARY KEY (rname, fname) 
);

CREATE TABLE Restaurant_Staff (
	userId 		INTEGER,
	rname		VARCHAR(20) REFERENCES Restaurants on DELETE CASCADE on UPDATE CASCADE,
	PRIMARY KEY (userId),
	FOREIGN KEY (userId) REFERENCES Users
			on DELETE CASCADE
			on UPDATE CASCADE
);


CREATE TABLE Customers (
	userId 		INTEGER,
	creditCardInfo	VARCHAR(100),
    PRIMARY KEY (userId),
	FOREIGN KEY (userId) REFERENCES Users
		on DELETE CASCADE
		on UPDATE CASCADE
);

CREATE TABLE Riders (
	userId 		INTEGER,
	area 		VARCHAR(20) NOT NULL,
    PRIMARY KEY (userId),
	FOREIGN KEY (userId) REFERENCES Users
			on DELETE CASCADE
			on UPDATE CASCADE
--             DEFERRABLE INITIALLY DEFERRED
    ,
	CHECK(area = 'central' OR
		 area = 'west' OR
		 area = 'east' OR
		 area = 'north' OR
		 area = 'south')
);

CREATE TABLE Part_Time (
   userId 		INTEGER,
   PRIMARY KEY (userId),
   FOREIGN KEY (userId) REFERENCES Riders
       on DELETE CASCADE
       on UPDATE CASCADE
--        DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE Full_Time (
    userId 		INTEGER,
    PRIMARY KEY (userId),
	FOREIGN KEY (userId) REFERENCES Riders 
			on DELETE CASCADE
			on UPDATE CASCADE
--             DEFERRABLE INITIALLY DEFERRED

);

CREATE TABLE Schedules (
	scheduleId SERIAL,
	userId INTEGER,
	startDate date,
	endDate date,
	PRIMARY KEY (scheduleId),
	FOREIGN KEY (userId) REFERENCES Riders(userId),
	check ((endDate - startDate) = 7)
);

CREATE TABLE Monthly_Work_Schedules (
	scheduleId	INTEGER REFERENCES Schedules,
	PRIMARY KEY (scheduleId)
	--DEFERRED TRIGGER TO CHECK FOR CONSTRAINTS (FOR BOTH INTERVAL & SCHEDULE)
);

CREATE TABLE Weekly_Work_Schedules (
	scheduleId	INTEGER  REFERENCES Schedules,
	PRIMARY KEY (scheduleId)
	--DEFERRED TRIGGER TO CHECK FOR CONSTRAINTS (FOR BOTH INTERVAL & SCHEDULE)
);

CREATE TABLE Intervals (
	intervalId INTEGER,
	scheduleId INTEGER,
	startTime TIMESTAMP,
	endTime TIMESTAMP,
	PRIMARY KEY (intervalId),
	FOREIGN KEY (scheduleId) REFERENCES Schedules(scheduleId)
	deferrable initially deferred,
	check (DATE_PART('minutes', startTime) = 0
	AND
	DATE_PART('seconds', startTime) = 0
	AND
	DATE_PART('minutes', endTime) = 0
	AND
	DATE_PART('seconds', startTime) = 0
	AND
	DATE_PART('hours', endTime) - DATE_PART('hours', startTime) <= 4
	AND
	startTime::date = endTime::date
	AND
	DATE_PART('hours', endTime) > DATE_PART('hours', startTime)
	AND
	startTime::time >= '10:00'
	AND
	endTime::time <='22:00'
	)
);


--able to share the same promoCode
CREATE TABLE Promotions (
	promoCode	    VARCHAR(20),	
	promoDesc 		VARCHAR(200),
	createdBy	    VARCHAR(50), --?
	applicableTo	VARCHAR(200) REFERENCES Restaurants(rname) ON DELETE CASCADE,
	discUnit	    VARCHAR(20) NOT NULL,
	discRate	    VARCHAR(20) NOT NULL,
	startDate	    TIMESTAMP NOT NULL,
	endDate	        TIMESTAMP NOT NULL,
	PRIMARY KEY (promoCode, applicableTo)
);

CREATE TABLE Orders (
	orderId 		INTEGER,
	userId 			INTEGER NOT NULL REFERENCES Customers ON DELETE CASCADE ON UPDATE CASCADE,
	promoCode		VARCHAR(20),
    applicableTo	VARCHAR(200),
	modeOfPayment 	VARCHAR(10) NOT NULL,
	timeOfOrder		TIMESTAMP NOT NULL,
	deliveryLocation	VARCHAR(100) NOT NULL,
	usedRewardPoints	INTEGER DEFAULT 0,
	givenRewardPoints	INTEGER NOT NULL,
	reviewContent		    VARCHAR(100),
	PRIMARY KEY(orderId),
	FOREIGN KEY(promoCode, applicableTo)  REFERENCES Promotions,
	CHECK(modeOfPayment = 'cash' OR
		 	modeOfPayment ='credit')
);

CREATE TABLE Order_Details (
	orderId 		INTEGER REFERENCES Orders ON DELETE CASCADE ON UPDATE CASCADE,
	rname			VARCHAR(100),
	fname 			VARCHAR(100),
	foodQty		    INTEGER NOT NULL,
	PRIMARY KEY(orderId, rname, fname),
	FOREIGN KEY(rname, fname) REFERENCES Sells(rname, fname),
	CHECK(foodQty >= 1)
);

CREATE TABLE Delivery_Details (
    orderId			        	INTEGER REFERENCES Orders ON DELETE CASCADE ON UPDATE CASCADE,
	userId				        INTEGER NOT NULL,
	departTimeForRestaurant	    TIMESTAMP,
	departTimeFromRestaurant    TIMESTAMP,
	arrivalTimeAtRestaurant	    TIMESTAMP,
	deliveryTimetoCustomer	    TIMESTAMP,
	rating					    INTEGER,
    PRIMARY KEY (orderId),
	FOREIGN KEY (userId) REFERENCES Riders on DELETE CASCADE,
	CHECK(rating <= 5)
);

CREATE TABLE MinSpendingPromotions (
	promoCode	    VARCHAR(20),	
	applicableTo	VARCHAR(200),
	minAmt	        NUMERIC(8, 2) DEFAULT 0,
	PRIMARY KEY (promoCode, applicableTo),
	FOREIGN KEY (promoCode, applicableTo) REFERENCES Promotions ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE CustomerPromotions (
    	promoCode		VARCHAR(20),	
	applicableTo	VARCHAR(200),
	minTimeFromLastOrder 	INTEGER, -- # of days
	PRIMARY KEY (promoCode, applicableTo),
	FOREIGN KEY (promoCode, applicableTo) REFERENCES Promotions ON DELETE CASCADE ON UPDATE CASCADE
);
