# Circa

A system for managing requests for special collections materials. The application includes a JSON API, built in Ruby on Rails, and a default front end written in Angular.js (v. 1.6.x).

Circa provides close integration with ArchivesSpace, upon which the application depends for managing containers associated with specific collection components, as well as the location of those containers. It can also support requests for materials described in an ILS.


# System requirements

* Ruby 2.2.1 or higher
* Rails 4.2.0 or higher
* MySQL
* Solr 5
* Redis (to support notifications)


# Installation

All of the following assume that you have Ruby (version 2.)
## Clone repository

## Install Solr

## Create Solr core

## Install Redis (optional)



# Configuration

Several YAML files are used to set environment variables used by the application to facilitate communication with other systems and components. In each case, settings can be made per environment, with the ability to define inheritable default values. Settings defined at the environment level will override the defaults.

Environment variables can be referenced in code via the `ENV` constant, eg:

```
ENV['solr_host']
```

There are example versions of these YAML files included in this repo, with "\_example" appended to the file name. You should create copies of these files renamed with "\_example" removed, eg:

archivesspace_example.yml -> archivesspace.yml


## config/database.yml

Edit this file with the appropriate options for your database. This is a standard Rails config file. For more info, see the [Rails configuration documentation](http://edgeguides.rubyonrails.org/configuring.html#configuring-a-database)


## config/archivesspace.yml

Defines variables required to communicate with the ArchivesSpace API and provide links to the ArchviesSpace staff interface.

* **archivesspace\_backend_port**: Port number (as a string) of ArchivesSpace back end (default: '8089')
* **archivesspace\_frontend_port**: Port number (as a string) of ArchivesSpace front end/ staff interface (default: '8080')
* **archivesspace\_solr_port**: Port number (as a string) of ArchivesSpace Solr index (default: '8090')*
* **archivesspace\_solr\_core_path**: path (from URL root) to the ArchivesSpace Solr core (default: '/collection1/')*
* **archivesspace_username**: User name used to connect to ArchivesSpace. User should have read access to all resources (default: 'admin')
* **archivesspace_password**: Password associated with ArchivesSpace API user (default: 'admin')

\* Note that, while there are methods available to communicate with the ArchivesSpace Solr index, this functionality is not currently being used in the application


## config/solr.yml

Defines variables required to connect to your Solr index.

* **solr_host**: The host name of your active Solr 5 installation (default: 'localhost')
* **solr_port**: The port on which your Solr instance is running (default: '8983')
* **solr\_core_path**: The path to the Solr core used by Circa (default: '/solr/circa/')


## config/email.yml

Defines variables required for email notifications sent by Circa.

* **order\_notification\_default_email**: Comma-separated list of email addresses to receive notifications when an order is created
* **order\_notification\_digital\_items_email**: Comma-separated list of email addresses to receive notifications when an order is created that includes digital items
* **circa_email**: 'From' email address on emails sent by Circa
* **circa\_email\_display_name**: 'From' display name on emails sent by Circa


# User guide

See [User guide](user_guide/user_guide.md) for detailed instruction on using Circa.


# Back end functionality overview

## Data model

The application defines four primary classes:

* **Order** - a request for materials
* **Item** - an individual item that can be requested and delivered for use (e.g. a box, volume, etc.)
* **User** - any person (either a staff member or a patron) associated with an order, or staff serving in an administrative capacity.
* **Location** - a physical location to or from which Items can be moved


### Orders

Orders are classified within 4 high-level order types:

* research - request for on-site use of materials for research
* reproduction - requests for reproductions of materials for off-site use or publication
* exhibition/loan - requests for long-term use for exhibition or similar purposes
* processing/preservation - requests for use of materials by staff for processing, preservation or other internal use

Each of these order types has a two or more sub-types that allow orders to be categorized more granularly.

Order types and subtypes can be used as conditions by which front end functionality can be added to or hidden from forms and displays.


### Items

All data required to create an Item in Circa comes from ArchivesSpace. ILS integration is also possible but no implementation for specific systems is included.

The process is initiated by providing Circa with the URI identifying an ArchivesSpace ArchivalObject record **[TK - SOMETHING ABOUT OUR PLUGIN FOR ADDING URI TO VIEW IN ASpace ]**. Circa will make a request to the ArchivesSpace API endpoint (including the option to resolve the associated resource) and use the data returned to create one or more Item records, determined by the number of top containers represented in the record's instances. In most cases, a single ArchivalObject record will have a single instance associated with a single top container, resulting in a single Item.

**Circa is opinionated about which containers are requestable.** It assumes that requests will be made at the top container (e.g. 'box') level, as opposed to the sub-container (e.g. 'folder') level.

When the Item is created, a corresponding Location record will be created (if a record for the same location does not already exist). Circa will assign this as the Item's permanent location. See blow for more info on Locations.


### Users

The User model is used for both researchers/patrons and for staff users of Circa. Circa uses Devise for authentication, and the User model includes all of the attributes that are provided with the Devise registration module.

Users are categorized by user role and patron type.


#### User roles

User roles provide high-level categorization of users. The default roles are:

* superadmin
* admin
* staff
* assistant
* patron

Roles are used to provide authorization of some functionality in the system (currently just for admins). Each role is assigned a level (integer) which determines the User's level of access. A user with a role with a lower level has all of the privileges of roles with higher level values.


#### Patron type

Every user, even staff, currently have to be assigned a patron type. This value is primarily for reporting purposes - there is no variable functionality associated with patron types.


### Locations

There are two kinds of locations in Circa:

1. Locations of Items' associated ArchivesSpace containers. These locations are imported from ArchivesSpace and cannot be modified in Circa.
2. Use locations, i.e. the location where materials will be transferred for use. These locations are created in Circa and can be modified.

Each item is assigned a permanent location and a current location. Upon creation these values are the same.

Each Order is assigned a use location. As Items on an Order are transferred to the Order's use location, the Item's current location is updated to the use location. Current location of Items can also be changed arbitrarily as needed.


## Record state

Circa manages state for Orders and Items, and state changes are persisted in the database to provide an audit trail.

For each model, a corresponding state configuration file (<model_name>_state_config.rb) can be found in app/models/concerns/. This file is used to define states, events that trigger transition to a specific state, rules defining conditions under which specific events/state changes are permitted, and callback methods to be executed after state changes have been completed.


## JSON API

Communication between the front-end and data stores (application database, Solr, ArchivesSpace, library catalog) is accomplished via a JSON API. See [API documentation](api.md) for more information.


## Solr configuration

The directory `solr_conf` includes configuration files for use with Solr 5. To use it, first create a new Solr core called 'circa'. By default, your core will include a directory called `conf` containing configuration files. Delete this directory and create a symbolic link from `conf` to the `solr_conf` directory in the location where Circa is deployed.

Alternately, you can specify the location of the custom config directory within the `core.properties` file in your core.


## Background job queuing

Circa uses the Active Job framework (included with Rails) to handle background jobs (primarily for sending email notifications asynchronously). Active Job is configured to use the [Resque](https://github.com/resque/resque) library for its queuing backend. Resque uses Redis, which must be installed and running on the server on which Circa is installed.


