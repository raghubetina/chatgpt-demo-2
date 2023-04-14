Rails.application.routes.draw do

  get("/", { :controller => "quizzes", :action => "index" })

  # Routes for the Message resource:

  # CREATE
  post("/insert_message", { :controller => "messages", :action => "create" })

  #------------------------------

  # Routes for the Quiz resource:

  # CREATE
  post("/insert_quiz", { :controller => "quizzes", :action => "create" })
          
  # READ
  get("/quizzes", { :controller => "quizzes", :action => "index" })
  
  get("/quizzes/:path_id", { :controller => "quizzes", :action => "show" })

  #------------------------------

end
