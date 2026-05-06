# The Perfect Framework

## By Michael Hunter © 2024 all rights reserved

So you are starting a new project, what are the things you wish your framework did for you, so you didn't have to spend your time setting up all these different pieces?

# Scale

Engineering shouldn’t have to worry about scale of application \- the Framework should be set to scale

# Database

* Audit trails \- who knew what when  
  * Point-in-time database \- [Point in time Architecture](https://docs.google.com/document/d/1UfZOXMWVU82NBSoTuiPRTqXIYBrhWu7iOk-tk7usWEA/edit?usp=sharing)  
  * Archive tables/Streams \- save the data so you can reproduce the changes were necessary  
* This work should and could be done by the database  
  * Auto Increment Table IDs  
  * Enforce foreign keys?  
    * Enforce them as much as you can, until affects performance  
    * Have a fully constrained database for developer  
    * Transactional ACID  
* DB VCS \- Database should be versionable just like code.  It should connect, detect and upgrade/downgrade to match applications.  
  * Liquibase  
* Document Database  
  * MongoDB or  
  * Postgres JSONB  
  * Document Schema migration and version management  
* Streaming Databases  
  * [What is a stream Database](https://www.upsolver.com/blog/what-is-a-streaming-database)

## Enterprise Messaging

Today's apps don't want to be polled.  It should allow messages to be pushed to and from the server.  
	activemq  
	Mqtt  
	Rabbitmq

# Security

* Single sign on  
* Authorization \-  
* data permissions   
* Access control  role based access control  
* Menu/Form/Field level control

# Application

* Platform Supported  
  * Android  
  * iOS  
  * Computer (Windows/Mac/Linux/Embedded)  
  * Web browser  
* Model Driven Architecture  
  * Dynamic   
    * field positioning  
    * form design  
    * Field level permission?  
    * Validation  
  * Infrastructure as configuration and code  
* User/System Preferences  
* Work offline/online  
* Localization  
  * Currency  
  * Date format  
  * ...  
* Internationalization  
  * Language support  
  * Translation  
* Accesability  
  * Blind and color/contrast  
    * Age  
    * Color blind  
    * …  
  * Deaf  
  * etc.  
* internal help system  
* analytics  
* units of measure  
  * Time  
  * GEO  
  * Standard  
    * Length  
    * Weight  
    * ….  
  * Currency  
* Workflow \- State Management  
  * StateChart  
  * Commitment  
    * propose  
    * agree  
    * perform  
    * Accept  
    * Compensate  
* CI/CD  
  * Support Multiple Environments  
    * Local Development  
    * Staging/QA  
    * Production  
  * Versioned build artifacts  
    * One Button Build  
* Documentation Systems  
  * Code Documentation  
  * User Documentation  
* User Feedback everywhere,  
  * ai behind to speed creation

Other  
	Unit Testing  
	MVC  
	Mobile  
