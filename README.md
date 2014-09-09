Coupon validation, Marketing campaign/User mangement/CRM addons to any Online/Offline Pay system
=========

this platform providing valuable addons to the paying system(like POS) that connects to and implement the client specification of the platform

* Successful Stories

  
  www.aishua.cn, providing closed coupon validation via smart POS terminal 

* Up and runing for development
  
  ```
   bundle install
   rake db:mirgate
   rake db:seed
   bundle exec foreman start
  
  ```

* Up and runing for production
   
   oh that's another story ;-)

* Components
   
   Admin panel:  Admin UI to manage the System
   
   Engine API: the entry point for paying system to connect and implements specification, restful API and [Swagger](http://swagger.io/) compliant, you can use [Swagger UI](https://github.com/wordnik/swagger-ui) to view and play with it, via http://domain-name/engine/api-docs

   Interface API: expose data of the platform to external system, like a website for content showing and user interface. restful API

