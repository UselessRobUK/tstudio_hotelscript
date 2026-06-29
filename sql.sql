CREATE TABLE hotel_rentals (
    id INT AUTO_INCREMENT,
    identifier VARCHAR(255),
    hotel VARCHAR(50),
    room INT,
    expires INT,
    PRIMARY KEY (id)
);
