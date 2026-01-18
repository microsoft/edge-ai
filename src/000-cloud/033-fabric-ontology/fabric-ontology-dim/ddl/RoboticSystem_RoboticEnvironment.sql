
CREATE TABLE RoboticSystem_RoboticEnvironment (
  Id STRING NOT NULL,
  FromId STRING NOT NULL,
  ToId STRING NOT NULL,
  RelationType STRING,
  Namespace STRING,
  Source STRING,
  PRIMARY KEY (Id)
);
