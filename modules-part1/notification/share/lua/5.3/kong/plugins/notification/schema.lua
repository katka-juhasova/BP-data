-- will send notification to different url with different methods for different APIs and customers
return {
 fields = {
   url = {type = "url", required = true},
   method = {type = "string", required = true ,enum ={"GET","POST","PUT"}},
   timeout = {default= 10000, type= "number" },
   keepalive = {default = 60000, type = "number"},
   sockettable = {}
 }
}
