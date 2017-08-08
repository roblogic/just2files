# -----------------------
# PLS Automated Smoketest
# -----------------------
#
# RunPLSFlow.rb
#
# Automated Test Cases ~ typical PLS user flows
#
require 'BaseService'
require 'watir'
require 'watir/testcase'
require 'watir/assertions'
require 'test/unit/assertions'
include BaseService
include Test::Unit::Assertions

class RunPLSFlow < Test::Unit::TestCase

  def test_suite
    # ==================== F L O W S ====================== #   
    # This is the default test case                         #
    # Uncomment one of the following to test a PLS flow     #
    # ====================~=========~====================== #
    #~ default_warnings     # warn the user that all tests will run

    #get_then_login($env.ta1sam2_url, "watir001", "anaymized@gmail.com")
    #get_then_login($env.ta2sam2_url, "watir002", "anonymized@gmail.com")
    #activate_token_exist($env.token_sn, "watir001")
    #consolidate_MSL_LSL("watir001", "watir002")
    #delete_user_MSL("watir001", "Password1")
    #activate_token_newuser($env.token_sn, "watir001", "anonymized@gmail.com")
    #deactivate_token("watir002", "Password1")
    #reset_password1("ta2admin", "Password1")
    #change_password("ta2sam2", "Secret1", "Password000")
    run_activity_summary
  end

  def setup
    $ie = Watir::IE.new
    $ie.set_fast_speed  #comment this out to slow things down
    $env = TestEnv.new("ORT")  #can be: VUAT, ORT, PROD
  end

  def teardown
    #$ie.close if defined? $ie
  end

private
  #~ Use "private" so that Test::Unit does not automatically run the stuff below   

  def test_ALL_PROD_Smoketest
    get_then_login($env.ta1sam2_url, "watir001", "anonymized@gmail.com")
    get_then_login($env.ta2sam2_url, "watir002", "anonymized@gmail.com")
    activate_token_exist($env.token_sn, "watir001", "Password1")
    consolidate_LSL_MSL("watir001", "watir002")
    reset_password1("watir001", "Password1")
  end

  def test_get_then_login
    get_then_login($env.ta2sam2_url, "watir002", "anonymized@gmail.com")
  end
  
  def test_delete_user
    delete_user_LSL("watir001", "Password1")
  end
  
  def test_run_activity_summary
    run_activity_summary
  end
  
  def test_change_password
    # basic password change
    # call change_password(url, id, passwd, newpass)
    change_password(env.my_userid, env.my_userpass, "Password404")
  end
  
  def test_recover_password
    # new password is retreived from email, then changed to "Password404"
    # call recover_password(url, id, email, newpass)
    recover_password(env.my_userid, env.my_email, "Password404")
  end

  def test_reset_password1
    # change password back to "Password1" by cycling through 6 password changes
    # call reset_password1(userid, current-passwd)
    reset_password1(env.my_userid, "Password1")
  end

  def test_activate_token_exist
    # assumes that "watiruser" does not have token assigned
    # call activate_token_exist(url, tsn, id, passwd)
    activate_token_exist(53064234, env.my_userid, env.my_userpass)
  end

  def test_deactivate_token
    # assumes that "watiruser" has token assigned
    # call deactivate_token(url, id, passwd)
    #~ deactivate_token(env.pls_home_url, env.my_userid, env.my_userpass)
    deactivate_token("watir001", "Password1")
  end

end

class TestEnv
  # I suppose TestEnv could be integrated into RunPLSFlow somehow, 
  # but this works well enough
    
  def initialize(environment_name)
    case environment_name
    when "PROD"
      @pls_home_url     = "https://www1.logon.initech.com/"               # PROD PLS Home
      @pls_helpdesk_url = "https://logon.initech.com/cls/HelpDesk"        # PROD Helpdesk
      @pls_token_url    = "http://www.logon.initech.com/cls/activatetoken"
      @ta1sam2_url      = "https://www.plstestagency.initech.com/ref-agency1/ref/Home"
      @ta2sam2_url      = "https://www3.sa.logon.initech.com/ref-agency2/ref/Home"
      @hd_userid        = "mauser404"
      @hd_userpass      = "Password404"
      @my_userid        = "watiruser"
      @my_userpass      = "Password1"
      @my_email         = "joe.bloggs@initech.com"
      @token_sn         = 53064234        # Serial Number on the back of the RSA token
    when "ORT"
      @pls_home_url     = "https://ort.logon.initech.com/"                 # ORT PLS Home
      @pls_helpdesk_url = "https://ort.logon.initech.com/cls/HelpDesk"     # ORT Helpdesk
      @pls_token_url    = "http://ort.logon.initech.com/cls/activatetoken"
      @ta1sam2_url      = "https://www.plstestagency.initech.com/ref-agency1-ort/"  
      @ta2sam2_url      = "https://www3.sa.logon.initech.com/ref-agency2-ort/"
      @hd_userid        = "ort1"
      @hd_userpass      = "Helpdesk1"
      @my_userid        = "watiruser"
      @my_userpass      = "Password1"
      @my_email         = "joe.bloggs@initech.com"
      @token_sn         = 52480246
    else                              
      # default to "VUAT"
      @pls_home_url     = "https://vuat.logon.initech.com/"               # VUAT PLS Home
      @pls_helpdesk_url = "https://vuat.logon.initech.com/cls/HelpDesk"   # VUAT Helpdesk
      @pls_token_url    = "http://vuat.logon.initech.com/cls/activatetoken"
      @ta1sam2_url      = "https://www.plstestagency.initech.com/ref-agency1-vuat/"   
      @ta2sam2_url      = "https://www3.sa.logon.initech.com/ref-agency2-vuat/"
      @hd_userid        = "hdo1"
      @hd_userpass      = "Helpdesk123"
      @my_userid        = "watiruser"
      @my_userpass      = "Password1"
      @my_email         = "joe.bloggs@initech.com"
      @token_sn         = 52480246
    end
    puts ("Environment initialized to #{environment_name}")
  end
  attr_reader :pls_home_url, :pls_helpdesk_url, :pls_token_url, :ta1sam2_url, :ta2sam2_url, \
              :hd_userid, :hd_userpass, :my_userid, :my_userpass, :my_email, :token_sn

end

# Exception handling 
# adapted from http://svn.instiki.org/instiki/trunk/test/watir/e2e.rb
begin
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.new(RunPLSFlow.suite).start
rescue => e
    $stderr.puts 'Unhandled error during test execution'
    $stderr.puts e.message
    $stderr.puts e.backtrace
ensure 
  begin 
    # Commented out - it's better to leave IE window open if there's an error!
    # RunPLSFlow::teardown    
  rescue => e
    $stderr.puts 'Error during shutdown'
    $stderr.puts e.message
    $stderr.puts e.backtrace
  end
end

