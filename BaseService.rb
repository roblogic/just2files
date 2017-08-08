# -----------------------
# PLS Automated Smoketest
# -----------------------
#
# BaseService.rb
#
# Module to provide all functions to support the automation
# (works better than a Class)
#
#
require 'watir'
require 'win32ole'  # for get_input routine
require 'test/unit' # for ASSERT tests
require 'watir/assertions'
require 'test/unit/assertions'
require 'dl'

module BaseService

def initialize
  # do this first, or else Ruby complains.
end

def message_box(txt='', title='', buttons=0, icon=0)
  user32 = DL.dlopen('user32')
  msgbox = user32['MessageBoxA', 'ILSSI']
  r = msgbox.call(0, txt, title, buttons+icon)
  return r
  #### button/icon constants
  #~ BUTTONS_OK = 0                 #~ BUTTONS_OKCANCEL = 1
  #~ BUTTONS_ABORTRETRYIGNORE = 2   #~ BUTTONS_YESNO = 4
  #~ ICON_HAND = 16                 #~ ICON_QUESTION = 32
  #~ ICON_EXCLAMATION = 48          #~ ICON_ASTERISK = 64
  #### return code constants
  #~ CLICKED_OK = 1                 #~ CLICKED_CANCEL = 2
  #~ CLICKED_ABORT = 3              #~ CLICKED_RETRY = 4
  #~ CLICKED_IGNORE = 5             #~ CLICKED_YES = 6
  #~ CLICKED_NO = 7
end

def get_input(prompt='', title='')
  # This little thing pops up an input box to get around the CAPTCHA 
  # Requires MS Excel to be installed as it calls an Excel object
  excel = WIN32OLE.new('Excel.Application')
  response = excel.InputBox(prompt, title)
  excel.Quit
  excel = nil
  return response
end

def log_msg(msg)
  puts("#{Time.now.strftime('%Y-%m-%d %X')} #{msg}")
end

def default_warnings
  msgtext="Warning: No test to run!\n\n Please run your test as follows:
     ruby RunPLSFlow.rb -n {test-name}\n e.g.
     ruby RunPLSFlow.rb -n test_run_activity_summary    "
  #message_box(msgtext, "Warning", 0, 48)
  log_msg(msgtext)
end  

def get_then_login(url, userid, email)
  #
  # get-then-login
  #
  ie = $ie
  @url = url    # for TA1 only use: @url = $env.ta1sam2_url
  @userid = userid
  @email = email
  @passwd = "Password1"
  ie.goto(@url)
  log_msg("navigated to #{@url}")

  log_msg("@@ Agency page")
  if ie.text.include?("There is a problem with this website's security certificate.")  
    log_msg("bypassing TA certificate error")
    ie.link(:name, "overridelink").click      
  end
 
  ie.button(:name, "btnLogon").click

  log_msg("@@ PLS login page")
  ie.link(:text, "Don't have a logon yet?").click

  log_msg("@@ Create New User page")
  ie.text_field(:name,"userId").value = @userid
  ie.text_field(:name,"emailAddress").value = @email
  ie.text_field(:name,"passwordOne").value = @passwd
  ie.text_field(:name,"passwordTwo").value = @passwd
  ie.button(:id,"subbutton").click

  # if "watir<i>" user already exists ...
  while ie.text.include?("The username you have chosen is invalid")
    log_msg("#{@userid} username is taken, trying next")
    i = @userid.match(/[0-9].*/).to_s.to_i
    i += 1
    @userid = "watir" << "%03d" % i      # watir001, watir002 etc.
    ie.text_field(:name,"userId").value = @userid
    ie.text_field(:name,"emailAddress").value = @email
    ie.text_field(:name,"passwordOne").value = @passwd
    ie.text_field(:name,"passwordTwo").value = @passwd
    ie.button(:id,"subbutton").click
  end
  
  log_msg("@@ CAPTCHA entry page")
  ie.text_field(:name,"captchaCharacters").value="qqqq" #deliberate error
  ie.button(:id,"subbutton").click
  # --loop until user enters correct captcha text
  while ie.text.include?("One or more fields have been left blank or are invalid. Please update as indicated")
    @response = get_input('Please enter the CAPTCHA text here.', 'Captcha input') 
    ie.text_field(:name,"captchaCharacters").value = @response
    ie.button(:id,"subbutton").click
  end

  log_msg("@@ New User Confirmation page")
  ie.button(:name,"Continue").click

  log_msg("@@ Terms & Conditions page")
  log_msg("starting t & c")
  ie.radio(:index,1).set
  ie.button(:name,"_eventId_continue").click
  log_msg("saved t & c")

  log_msg("@@ Terms & Conditions Accepted page")
  ie.button(:name,"ContinueButton").click

  log_msg("@@ Update Your Login Profile page")
  log_msg("starting user profile")
  ie.select_list(:name,"phoneIntl").select("+64")
  ie.text_field(:name,"phoneArea").value="99"
  ie.text_field(:name,"phoneNumber").value="9999999"

  log_msg("starting security qu")
  ie.select_list(:name,"question1").select("What is the name of the suburb you first grew up in?")
  ie.text_field(:name,"answer1").set("ok")
  ie.select_list(:name,"question2").select("What was the primary school you attended the most?")
  ie.text_field(:name,"answer2").set("ok")
  ie.select_list(:name,"question3").select("What was the secondary school you attended the most?")
  ie.text_field(:name,"answer3").set("ok")

  ie.button(:id,"subbutton").click
  log_msg("saved profile details")

  log_msg("@@ Your Login Profile Confirmation page")
  ie.button(:name,"Continue").click
  log_msg("confirmation: created user #{@userid}")

  log_msg("@@ Agency Profile page")
  log_msg("back at test agency")
  if ie.text.include?("You are not logged on.") or ie.text.include?("Error Page")  
    log_msg("whoops -- TA timeout problem")
    loginTA_LSL(@url, @userid, @passwd)      
    ie.button(:name,"btnMaintainAgencyAccount").click
  end
  
  ie.text_field(:name,"firstname").value="Watir"
  ie.text_field(:name,"lastname").set("Script")
  ie.text_field(:name,"email").set("someone@test.gmail.com")
  ie.text_field(:name,"phoneCountry").set("+64")
  ie.text_field(:name,"phoneArea").set("99")
  ie.text_field(:name,"phoneNo").set("9999999")
  ie.button(:name,"_eventId_Save").click

  log_msg("@@ Agency Welcome User page")
  ie.button(:name,"btnLogout").click

  log_msg("@@ Agency Welcome Guest page")
  # try some assert/verify tests
  assert(ie.pageContainsText("Welcome to the Test Agency"))        
  assert(ie.pageContainsText("You have logged out successfully"))  
  ie.button(:name,"btnLogon").click

  log_msg("@@ PLS login page")
  ie.button(:id,"cancelbutton").click

  log_msg("@@ Agency SAML Error page")
  assert(ie.pageContainsText("SAML2 Error Message Received from the PLS"))  
  assert(ie.pageContainsText("You have chosen to leave the PLS"))     
  ie.button(:name,"btnHome").click
end

def delete_user_LSL(idLSL,passwd)
  #
  # Delete user with Low-Strength login
  #
  ie = $ie
  @userid = idLSL
  @passwd = passwd
  log_msg("Deleting LSL user: #{@userid}")
  login_LSL(@userid, @passwd)
  ie.link(:text,"Delete a logon").click 

  log_msg("@@ Delete Your Login Step 1 page")
  ie.text_field(:name,"password").value="qqqqqqqqqqqqqqqqqqqqqqqqqq"
  ie.button(:id,"subbuttonAlt").click
  
  log_msg("@@ Delete Your Login Step 1 page (again)")
  assert(ie.pageContainsText("The existing password you have entered is incorrect"))
  ie.text_field(:name,"password").value=@passwd
  ie.button(:id,"subbuttonAlt").click

  log_msg("@@ Delete Your Login Step 2 Confirmation page")
  assert(ie.pageContainsText("Please confirm you want to delete this logon permanently"))
  ie.button(:name,"_eventId_Continue").click

  log_msg("@@ Logon Deleted page")
  assert(ie.pageContainsText("Your logon has been deleted and you are now logged out"))
  ie.button(:name,"Continue").click
  log_msg("#{@userid} was deleted")

  log_msg("@@ PLS Home page")
  assert(ie.pageContainsText("You are not logged on"))
  assert(ie.pageContainsText("The convenience of an initech public systems logon"))
  log_msg("good-bye")
end

def delete_user_MSL(idMSL,passwd)
  #
  # Delete user with Medium-Strength login
  #
  ie = $ie
  @userid = idMSL
  @passwd = passwd
  log_msg("Deleting MSL user: #{@userid}")
  login_MSL(@userid, @passwd)
  ie.link(:text,"Delete a logon").click 

  log_msg("@@ Delete Your Login Step 1 page")
  #deliberately submit error
  ie.text_field(:id,"password1").value="blah"
  ie.text_field(:id,"tokencode").value="0000"
  ie.button(:id,"subbuttonAlt").click
  
  while ie.text.include?("Sorry, your attempt was unsuccessful")
    ie.text_field(:id,"password1").value=@passwd
    @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
    ie.text_field(:id,"tokencode").value=@response
    ie.button(:id,"subbuttonAlt").click
  end

  log_msg("@@ Delete Your Login Step 2 Confirmation page")
  assert(ie.pageContainsText("Please confirm you want to delete this logon permanently"))
  ie.button(:name,"_eventId_Continue").click

  log_msg("@@ Logon Deleted page")
  assert(ie.pageContainsText("Your logon has been deleted and you are now logged out"))
  ie.button(:name,"Continue").click
  log_msg("#{@userid} was deleted")

  log_msg("@@ PLS Home page")
  assert(ie.pageContainsText("You are not logged on"))
  assert(ie.pageContainsText("The convenience of an all-of-government logon"))
  log_msg("good-bye")
end

def run_activity_summary()
  #
  # Run "Activity Summary" report
  #
  ie = $ie
  log_msg("Getting activity summary report")
  login_HDO()
  ie.button(:name,"_eventId_Activity Summary").click

  log_msg("start report")
  ie.button(:value,"Generate").click

  log_msg("change parameter")
  ie.button(:value,"Change Report Parameters").click

  log_msg("log out")
  ie.link(:title, "Log out.").click
end

def recover_password(userid, email, newpass)
  #
  # recover-password
  #
  ie = $ie
  @url = $env.pls_home_url
  @userid = userid
  @email = email
  @newpass = newpass
  ie.goto(@url)
  log_msg("navigated to #{@url}")

  log_msg("recovering password for user: #{@userid}, #{@email}")

  log_msg("@@ PLS Home page")
  ie.link(:text, "Manage your PLS logon now").click 

  log_msg("@@ PLS Login page")
  ie.link(:text,"Forgot your password?").click 

  log_msg("@@ Forgot Your Password Step 1 page")
  ie.text_field(:id,"username").value=@userid
  ie.text_field(:id,"useremail").value=@email
  ie.button(:id,"subbuttonAlt").click
  
  log_msg("@@ Forgot Your Password Step 2 page")
  ie.text_field(:id,"response1").value="ok"
  ie.text_field(:id,"response2").value="ok"
  ie.button(:id,"subbuttonAlt").click
 
  log_msg("@@ Password Sent page")
  assert(ie.pageContainsText("We have emailed you a temporary password. You'll need to use it the next time you log on."))
  log_msg("password sent to #{@email} -- check your inbox!")
  ie.link(:text, "Return to log on page").click

  log_msg("@@ PLS Login page")
  ie.text_field(:name,"username").value=@userid
  # user to enter temp passwd
  response = get_input("Temporary password has been emailed to #{@email}. Please check your mail and enter the temp password here:", 'Password input')
  ie.text_field(:name,"password").value=response
  ie.button(:id,"subbutton").click
  
  log_msg("@@ Password Expired page")
  assert(ie.pageContainsText("Your password has been expired for one of the following reasons"))
  ie.text_field(:id,"password1").value=response
  ie.text_field(:id,"password2").value=@newpass
  ie.text_field(:id,"password3").value=@newpass
  ie.button(:id,"subbuttonAlt").click
  
  log_msg("@@ Change your password Confirmation page")
  assert(ie.pageContainsText("You have successfully changed your password"))
  log_msg("password reset to #{@newpass}")
  ie.button(:name,"_eventId_Continue").click
  
  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("Home page > Manage your logon"))
  
  log_msg("log out")
  ie.link(:title, "Log out.").click
end

def change_password(userid, curpass, newpass)
  #
  # change-password
  #
  ie = $ie
  @userid = userid
  @curpass = curpass
  @newpass = newpass
  log_msg("Changing Password for user: #{@userid}")
  login_LSL(@userid, @curpass)
  ie.link(:text,"Change your password").click
  
  log_msg("@@ Change Your Password page")
  ie.text_field(:id,"password1").value=@curpass
  ie.text_field(:id,"password2").value=@newpass
  ie.text_field(:id,"password3").value=@newpass
  ie.button(:id,"subbuttonAlt").click
  
  log_msg("@@ Change your password Confirmation page")
  assert(ie.pageContainsText("You have successfully changed your password"))
  log_msg("Password was changed from \"#{@curpass}\" to \"#{@newpass}\"")
  ie.button(:name,"_eventId_Continue").click
  
  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("Home page > Manage your logon"))
  
  log_msg("log out")
  ie.link(:title, "Log out.").click
end

def reset_password1(userid, passwd)
  # 
  # Resets whatever password back to "Password1"
  # Iterates six times to get around the PLS comparison of previous passwords
  #
  ie = $ie
  @userid = userid
  @curpass = passwd
  log_msg("Resetting Password1 for user: #{@userid}")
  login_LSL(@userid, @curpass)
  
  for i in 1..7 do
    if i == 7
      @newpass = "Password1"
    else
      #set to Password111, Password222, etc.
      @newpass = "Password#{i}#{i}#{i}"  
    end
    ie.link(:text,"Change your password").click
    ie.text_field(:id,"password1").value=@curpass
    ie.text_field(:id,"password2").value=@newpass
    ie.text_field(:id,"password3").value=@newpass
    ie.button(:id,"subbuttonAlt").click
    assert(ie.pageContainsText("You have successfully changed your password"))
    log_msg("Password was changed from \"#{@curpass}\" to \"#{@newpass}\"")
    #reset current var 
    @curpass = @newpass
    ie.button(:name,"_eventId_Continue").click
  end
  log_msg("log out")
  ie.link(:title, "Log out.").click
end

def activate_token_exist(token_sn, userid)
  #
  # activate RSA token against existing user
  #
  ie = $ie
  @url = $env.pls_token_url
  @tsn = token_sn
  @userid = userid
  @passwd = "Password1"
  log_msg("Activating RSA Token #{@tsn}")
  log_msg("navigated to #{@url}")
  ie.goto(@url)
  
  log_msg("@@ PLS Token Setup page 1")
  assert(ie.pageContainsText("Enter your token serial number and tokencode"))
  ie.text_field(:id,"serialnumber").value=@tsn
  # get token code
  @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
  ie.text_field(:id,"tokencode").value=@response
  ie.button(:id,"subbuttonAlt").click  
  
  log_msg("@@ PLS Token Setup page 2")
  assert(ie.pageContainsText("Choose a username and password"))
  ie.text_field(:id,"username").value=@userid
  ie.text_field(:id,"userpassword").value=@passwd
  ie.button(:id,"subbutton").click  
  
  log_msg("@@ PLS Token Setup complete page")
  assert(ie.pageContainsText("You have successfully set up your PLS token"))
  assert(ie.pageContainsText("#{@tsn} for use with your username #{@userid}"))
  ie.button(:name,"Continue").click
  
  log_msg("@@ logged out to PLS Homepage")
  assert(ie.pageContainsText("You are not logged on"))
  assert(ie.pageContainsText("The convenience of an all-of-government logon"))
  log_msg("good-bye")
end

def activate_token_newuser(token_sn, userid, email)
  #
  # Activate RSA token and create a new user
  #
  ie = $ie
  @url = $env.pls_token_url
  @tsn = token_sn
  @userid = userid
  @email = email
  @passwd = "Password1"
  log_msg("Activating RSA Token #{@tsn}")
  log_msg("navigated to #{@url}")
  ie.goto(@url)
  log_msg("@@ PLS Token Setup page 1")
  assert(ie.pageContainsText("Enter your token serial number and tokencode"))
  ie.text_field(:id,"serialnumber").value=@tsn
  # get token code
  @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
  ie.text_field(:id,"tokencode").value=@response
  ie.button(:id,"subbuttonAlt").click  
  
  log_msg("@@ PLS Token Setup page 2")
  assert(ie.pageContainsText("Choose a username and password"))
  ie.link(:text, "Create Logon").click  #should hit the [Create Login] pseudo-button
  
  log_msg("@@ Get A Logon page")
  assert(ie.pageContainsText("You are logged on as #{@tsn} using your PLS Token"))
  assert(ie.pageContainsText("Please enter your preferred username, your email address and a password to create your logon"))

  ie.text_field(:id,"username").value=@userid
  ie.text_field(:id,"useremail").value=@email
  ie.text_field(:id,"password1").value=@passwd
  ie.text_field(:id,"passwordTwo").value=@passwd
  ie.button(:id,"subbutton").click  

  # if "watir<i>" user already exists ...
  i = @userid.match(/[0-9].*/).to_s.to_i
  while ie.text.include?("The username you have chosen is invalid")
    log_msg("#{@userid} username is taken, trying next")
    i += 1
    @userid = "watir" << "%03d" % i      # watir001, watir002 etc.
    ie.text_field(:id,"username").value=@userid
    ie.text_field(:id,"useremail").value=@email
    ie.text_field(:id,"password1").value=@passwd
    ie.text_field(:id,"passwordTwo").value=@passwd
    ie.button(:id,"subbutton").click
  end
  
  log_msg("@@ Get A Logon Confirmation page")
  assert(ie.pageContainsText("You are logged on as #{@tsn} using your PLS Token"))
  assert(ie.pageContainsText("You have successfully chosen your username and password"))
  ie.button(:name,"Continue").click

  log_msg("@@ Token Setup Complete page")
  assert(ie.pageContainsText("You are logged on as #{@userid} using your PLS Token"))
  assert(ie.pageContainsText("You have successfully set up your PLS token #{@tsn} for use with your username #{@userid}"))
  ie.button(:name,"Continue").click
  
  log_msg("@@ logged out to PLS Homepage")
  assert(ie.pageContainsText("You are not logged on"))
  assert(ie.pageContainsText("The convenience of an all-of-government logon"))
  
  #log on again and do T&C
  login_MSL(@userid,@passwd)
  log_msg("@@ Terms and Conditions page")
  assert(ie.pageContainsText("You are logged on as #{@userid} using your PLS Token"))
  ie.radio(:index,1).set
  ie.button(:name,"_eventId_continue").click

  log_msg("@@ Terms & Conditions Accepted page")
  ie.button(:name,"ContinueButton").click

  log_msg("@@ Your Login Profile - Attention")
  ie.button(:name,"_eventId_continue").click

  log_msg("@@ Update Your Login Profile page")
  log_msg("starting user profile")
  ie.select_list(:name,"phoneIntl").select("+64")
  ie.text_field(:name,"phoneArea").value="99"
  ie.text_field(:name,"phoneNumber").value="9999999"

  log_msg("starting security qu")
  ie.select_list(:name,"question1").select("What is the name of the suburb you first grew up in?")
  ie.text_field(:name,"answer1").set("ok")
  ie.select_list(:name,"question2").select("What was the primary school you attended the most?")
  ie.text_field(:name,"answer2").set("ok")
  ie.select_list(:name,"question3").select("What was the secondary school you attended the most?")
  ie.text_field(:name,"answer3").set("ok")

  ie.button(:id,"subbutton").click
  log_msg("saved profile details")

  log_msg("@@ Your Login Profile Confirmation page")
  ie.button(:name,"Continue").click

  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("You are logged on as #{@idMSL} using your PLS Token"))
  assert(ie.pageContainsText("Home page > Manage your logon"))

  log_msg("log out")
  ie.link(:title, "Log out.").click
  return    
end


def deactivate_token(idMSL, passwd)
  #
  # deactivate RSA token
  #
  ie = $ie
  @idMSL=idMSL
  @passwd=passwd
  log_msg("Deactivating RSA Token")
  login_MSL(@idMSL, @passwd)
  ie.link(:text,"Deactivate Token").click 

  log_msg("@@ Token deactivation page 1")
  assert(ie.pageContainsText("Enter your password and tokencode"))
  assert(ie.pageContainsText("to deactivate your PLS token logon"))
  # get token code
  @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
  ie.text_field(:id,"password").value=@passwd
  ie.text_field(:id,"tokencode").value=@response
  ie.button(:id,"subbuttonAlt").click  

  log_msg("@@ Token deactivation page 2")
  assert(ie.pageContainsText("Please confirm you want to deactivate this token"))
  ie.button(:id,"conbutton").click  

  log_msg("@@ confirmation page")
  assert(ie.pageContainsText("You have successfully deactivated your PLS token"))
  ie.button(:name,"Continue").click
  
  log_msg("@@ logged out to PLS Homepage")
  assert(ie.pageContainsText("You are not logged on"))
  assert(ie.pageContainsText("The convenience of an all-of-government logon"))
  log_msg("good-bye")
end

def consolidate_MSL_LSL(idMSL, idLSL)
  #
  # consolidate Medium-Strength login and Low-strength login 
  #
  ie = $ie
  @idMSL = idMSL
  @idLSL = idLSL
  @passwd = "Password1"
  log_msg("Consolidating users: #{@idMSL}, #{@idLSL}")
  login_MSL(@idMSL, @passwd)
  ie.link(:text,"Combine logons").click 

  log_msg("@@ Combine your Logins page 1")
  assert(ie.pageContainsText("Choose the logon you want to combine"))
  ie.text_field(:id,"username").value=@idLSL
  ie.text_field(:id,"userpassword").value=@passwd
  ie.button(:id,"subbuttonAlt").click

  log_msg("@@ Combine your Logins page 2")
  assert(ie.pageContainsText("You are combining a username and password logon with a PLS logon. The token must be kept."))
  assert(ie.pageContainsText("Please select the username you want to keep."))
  ie.radio(:id, "user1").set
  ie.button(:id,"subbutton").click
  assert(ie.pageContainsText("Confirm the logon you want to keep"))
  assert(ie.pageContainsText("This is the logon you have chosen to keep"))

  log_msg("@@ Combine your Logins page 3")
  ie.button(:id,"subbutton").click

  log_msg("@@ Combine your Logins Confirmation")
  assert(ie.pageContainsText("You have successfully combined your logons"))
  assert(ie.pageContainsText("You will use #{@idMSL} username to access services")) 
  ie.button(:name,"Continue").click

  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("You are logged on as #{@idMSL} using your PLS Token"))
  assert(ie.pageContainsText("Home page > Manage your logon"))

  log_msg("log out")
  ie.link(:title, "Log out.").click
  return  
end

def login_HDO()
  #
  # Log in Help Desk Operator for PLS user admin tasks  
  #
  ie = $ie
  @url = $env.pls_helpdesk_url
  @userid = $env.hd_userid
  @passwd = $env.hd_userpass
  ie.goto(@url)
  log_msg("navigated to #{@url}")
  ie.text_field(:id,"username").value=@userid
  ie.text_field(:id,"userpassword").value=@passwd
  # get token code
  response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
  ie.text_field(:id,"tokencode").value=response

  log_msg("log in")
  ie.button(:value,"Log on").click
end

def login_MSL(idMSL,passwd)
  #
  # Access PLS with Medium-Strength login
  #
  ie = $ie
  @url = $env.pls_home_url
  @userid = idMSL
  @passwd = passwd
  ie.goto(@url)
  log_msg("navigated to #{@url}")
  log_msg("@@ PLS Home page")
  log_msg("Logging on with Medium strength: #{@userid}")
  ie.link(:text, "Manage your PLS logon now").click 

  log_msg("@@ PLS Login page")
  ie.link(:text, "PLS token").click
  ie.text_field(:name,"username").value=@userid
  ie.text_field(:name,"password").value=@passwd
  # get token code
  @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
  ie.text_field(:id,"tokencode").value=@response
  ie.button(:id,"subbutton").click

  # Handle user typo or token out of sync 
  # Only 1 chance to re-enter, don't want an infinite loop  
  if ie.text.include?("Your log on attempt was unsuccessful")
    ie.text_field(:name,"username").value=@userid
    ie.text_field(:name,"password").value=@passwd
    @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
    ie.text_field(:id,"tokencode").value=@response
    ie.button(:id,"subbutton").click
  end
  
  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("You are logged on as #{@userid} using your PLS Token"))
  assert(ie.pageContainsText("Home page > Manage your logon"))
end

def login_LSL(idLSL,passwd)
  #
  # Access PLS with Low-strength login
  #
  ie = $ie
  @url = $env.pls_home_url
  @userid = idLSL
  @passwd = passwd
  ie.goto(@url)
  log_msg("navigated to #{@url}")
  log_msg("@@ PLS Home page")
  log_msg("Logging on with Low strength: #{@userid}")
  ie.link(:text, "Manage your PLS logon now").click 

  log_msg("@@ PLS Login page")
  ie.text_field(:name,"username").value=@userid
  ie.text_field(:name,"password").value=@passwd
  ie.button(:id,"subbutton").click

  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("Home page > Manage your logon"))
  return
end

def loginTA_LSL(url,idLSL,passwd)
  #
  # Access Agency with Low-strength login
  #
  ie = $ie
  @url = url
  @userid = idLSL
  @passwd = passwd
  ie.goto(@url)
  log_msg("navigated to #{@url}")
  log_msg("@@ Test Agency Home page")
  log_msg("Logging on with Low strength: #{@userid}")
  ie.button(:name, "btnLogon").click

  log_msg("@@ PLS Login page")
  ie.text_field(:name,"username").value=@userid
  ie.text_field(:name,"password").value=@passwd
  ie.button(:id,"subbutton").click

  log_msg("@@ PLS Manage your logon page")
  assert(ie.pageContainsText("Home page > Manage your logon"))
  return
end

def loginTA_MSL(url,idMSL,passwd)
  #
  # Access Agency with Medium-Strength login
  #
  ie = $ie
  @url = url
  @userid = idMSL
  @passwd = passwd
  ie.goto(@url)
  log_msg("navigated to #{@url}")
  log_msg("@@ Test Agency Home page")
  log_msg("Logging on with Medium strength: #{@userid}")
  ie.button(:name, "btnLogon").click

  log_msg("@@ PLS Login page")
  ie.link(:text, "PLS token").click
  ie.text_field(:name,"username").value=@userid
  ie.text_field(:name,"password").value=@passwd
  # get token code
  @response = get_input('Please enter the RSA token code here.', 'RSA Token input') 
  ie.text_field(:id,"tokencode").value=@response
  ie.button(:id,"subbutton").click

  log_msg("@@ Test Agency Welcome User page")
  assert(ie.pageContainsText("You are logged on with a Low Strength logon using your PLS Username & Password"))
  return
end

end
