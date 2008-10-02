require 'abstract_unit'
require 'action_controller/integration'
require 'action_controller/routing'

uses_mocha 'integration' do

module IntegrationSessionStubbing
  def stub_integration_session(session)
    session.stubs(:process)
    session.stubs(:generic_url_rewriter)
  end
end

class SessionTest < Test::Unit::TestCase
  include IntegrationSessionStubbing

  def setup
    @session = ActionController::Integration::Session.new
    stub_integration_session(@session)
  end

  def test_https_bang_works_and_sets_truth_by_default
    assert !@session.https?
    @session.https!
    assert @session.https?
    @session.https! false
    assert !@session.https?
  end

  def test_host!
    assert_not_equal "glu.ttono.us", @session.host
    @session.host! "rubyonrails.com"
    assert_equal "rubyonrails.com", @session.host
  end

  def test_follow_redirect_raises_when_no_redirect
    @session.stubs(:redirect?).returns(false)
    assert_raise(RuntimeError) { @session.follow_redirect! }
  end

  def test_follow_redirect_calls_get_and_returns_status
    @session.stubs(:redirect?).returns(true)
    @session.stubs(:headers).returns({"location" => ["www.google.com"]})
    @session.stubs(:status).returns(200)
    @session.expects(:get)
    assert_equal 200, @session.follow_redirect!
  end

  def test_request_via_redirect_uses_given_method
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue"}
    @session.expects(:put).with(path, args, headers)
    @session.stubs(:redirect?).returns(false)
    @session.request_via_redirect(:put, path, args, headers)
  end

  def test_request_via_redirect_follows_redirects
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue"}
    @session.stubs(:redirect?).returns(true, true, false)
    @session.expects(:follow_redirect!).times(2)
    @session.request_via_redirect(:get, path, args, headers)
  end

  def test_request_via_redirect_returns_status
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue"}
    @session.stubs(:redirect?).returns(false)
    @session.stubs(:status).returns(200)
    assert_equal 200, @session.request_via_redirect(:get, path, args, headers)
  end

  def test_get_via_redirect
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue" }
    @session.expects(:request_via_redirect).with(:get, path, args, headers)
    @session.get_via_redirect(path, args, headers)
  end

  def test_post_via_redirect
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue" }
    @session.expects(:request_via_redirect).with(:post, path, args, headers)
    @session.post_via_redirect(path, args, headers)
  end

  def test_put_via_redirect
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue" }
    @session.expects(:request_via_redirect).with(:put, path, args, headers)
    @session.put_via_redirect(path, args, headers)
  end

  def test_delete_via_redirect
    path = "/somepath"; args = {:id => '1'}; headers = {"X-Test-Header" => "testvalue" }
    @session.expects(:request_via_redirect).with(:delete, path, args, headers)
    @session.delete_via_redirect(path, args, headers)
  end

  def test_url_for_with_controller
    options = {:action => 'show'}
    mock_controller = mock()
    mock_controller.expects(:url_for).with(options).returns('/show')
    @session.stubs(:controller).returns(mock_controller)
    assert_equal '/show', @session.url_for(options)
  end

  def test_url_for_without_controller
    options = {:action => 'show'}
    mock_rewriter = mock()
    mock_rewriter.expects(:rewrite).with(options).returns('/show')
    @session.stubs(:generic_url_rewriter).returns(mock_rewriter)
    @session.stubs(:controller).returns(nil)
    assert_equal '/show', @session.url_for(options)
  end

  def test_redirect_bool_with_status_in_300s
    @session.stubs(:status).returns 301
    assert @session.redirect?
  end

  def test_redirect_bool_with_status_in_200s
    @session.stubs(:status).returns 200
    assert !@session.redirect?
  end

  def test_get
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    @session.expects(:process).with(:get,path,params,headers)
    @session.get(path,params,headers)
  end

  def test_post
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    @session.expects(:process).with(:post,path,params,headers)
    @session.post(path,params,headers)
  end

  def test_put
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    @session.expects(:process).with(:put,path,params,headers)
    @session.put(path,params,headers)
  end

  def test_delete
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    @session.expects(:process).with(:delete,path,params,headers)
    @session.delete(path,params,headers)
  end

  def test_head
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    @session.expects(:process).with(:head,path,params,headers)
    @session.head(path,params,headers)
  end

  def test_xml_http_request_get
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    headers_after_xhr = headers.merge(
      "X-Requested-With" => "XMLHttpRequest",
      "Accept"           => "text/javascript, text/html, application/xml, text/xml, */*"
    )
    @session.expects(:process).with(:get,path,params,headers_after_xhr)
    @session.xml_http_request(:get,path,params,headers)
  end

  def test_xml_http_request_post
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    headers_after_xhr = headers.merge(
      "X-Requested-With" => "XMLHttpRequest",
      "Accept"           => "text/javascript, text/html, application/xml, text/xml, */*"
    )
    @session.expects(:process).with(:post,path,params,headers_after_xhr)
    @session.xml_http_request(:post,path,params,headers)
  end

  def test_xml_http_request_put
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    headers_after_xhr = headers.merge(
      "X-Requested-With" => "XMLHttpRequest",
      "Accept"           => "text/javascript, text/html, application/xml, text/xml, */*"
    )
    @session.expects(:process).with(:put,path,params,headers_after_xhr)
    @session.xml_http_request(:put,path,params,headers)
  end

  def test_xml_http_request_delete
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    headers_after_xhr = headers.merge(
      "X-Requested-With" => "XMLHttpRequest",
      "Accept"           => "text/javascript, text/html, application/xml, text/xml, */*"
    )
    @session.expects(:process).with(:delete,path,params,headers_after_xhr)
    @session.xml_http_request(:delete,path,params,headers)
  end

  def test_xml_http_request_head
    path = "/index"; params = "blah"; headers = {:location => 'blah'}
    headers_after_xhr = headers.merge(
      "X-Requested-With" => "XMLHttpRequest",
      "Accept"           => "text/javascript, text/html, application/xml, text/xml, */*"
    )
    @session.expects(:process).with(:head,path,params,headers_after_xhr)
    @session.xml_http_request(:head,path,params,headers)
  end

  def test_xml_http_request_override_accept
    path = "/index"; params = "blah"; headers = {:location => 'blah', "Accept" => "application/xml"}
    headers_after_xhr = headers.merge(
      "X-Requested-With" => "XMLHttpRequest"
    )
    @session.expects(:process).with(:post,path,params,headers_after_xhr)
    @session.xml_http_request(:post,path,params,headers)
  end
end

class IntegrationTestTest < Test::Unit::TestCase
  include IntegrationSessionStubbing

  def setup
    @test = ::ActionController::IntegrationTest.new(:default_test)
    @test.class.stubs(:fixture_table_names).returns([])
    @session = @test.open_session
    stub_integration_session(@session)
  end

  def test_opens_new_session
    @test.class.expects(:fixture_table_names).times(2).returns(['foo'])

    session1 = @test.open_session { |sess| }
    session2 = @test.open_session # implicit session

    assert_equal ::ActionController::Integration::Session, session1.class
    assert_equal ::ActionController::Integration::Session, session2.class
    assert_not_equal session1, session2
  end
end

# Tests that integration tests don't call Controller test methods for processing.
# Integration tests have their own setup and teardown.
class IntegrationTestUsesCorrectClass < ActionController::IntegrationTest
  include IntegrationSessionStubbing

  def self.fixture_table_names
    []
  end

  def test_integration_methods_called
    reset!
    stub_integration_session(@integration_session)
    %w( get post head put delete ).each do |verb|
      assert_nothing_raised("'#{verb}' should use integration test methods") { __send__(verb, '/') }
    end
  end
end

class IntegrationProcessTest < ActionController::IntegrationTest
  class IntegrationController < ActionController::Base
    session :off

    def get
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
      respond_to do |format|
        format.html { render :text => "OK", :status => 200 }
        format.js { render :text => "JS OK", :status => 200 }
      end
    end

    def get_with_params
      render :text => "foo: #{params[:foo]}", :status => 200
=======
      render :text => "OK", :status => 200
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
    end

    def post
      render :text => "Created", :status => 201
    end
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
=======

    def cookie_monster
      cookies["cookie_1"] = nil
      cookies["cookie_3"] = "chocolate"
      render :text => "Gone", :status => 410
    end
  end
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb

<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
    def cookie_monster
      cookies["cookie_1"] = nil
      cookies["cookie_3"] = "chocolate"
      render :text => "Gone", :status => 410
    end

    def redirect
      redirect_to :action => "get"
    end
  end

=======
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
  def test_get
    with_test_route_set do
      get '/get'
      assert_equal 200, status
      assert_equal "OK", status_message
      assert_equal "200 OK", response.headers["Status"]
      assert_equal ["200 OK"], headers["status"]
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_response 200
      assert_response :success
      assert_response :ok
=======
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_equal [], response.headers["cookie"]
      assert_equal [], headers["cookie"]
      assert_equal({}, cookies)
      assert_equal "OK", response.body
      assert_kind_of HTML::Document, html_document
      assert_equal 1, request_count
    end
  end

  def test_post
    with_test_route_set do
      post '/post'
      assert_equal 201, status
      assert_equal "Created", status_message
      assert_equal "201 Created", response.headers["Status"]
      assert_equal ["201 Created"], headers["status"]
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_response 201
      assert_response :success
      assert_response :created
=======
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_equal [], response.headers["cookie"]
      assert_equal [], headers["cookie"]
      assert_equal({}, cookies)
      assert_equal "Created", response.body
      assert_kind_of HTML::Document, html_document
      assert_equal 1, request_count
    end
  end

  def test_cookie_monster
    with_test_route_set do
      self.cookies['cookie_1'] = "sugar"
      self.cookies['cookie_2'] = "oatmeal"
      get '/cookie_monster'
      assert_equal 410, status
      assert_equal "Gone", status_message
      assert_equal "410 Gone", response.headers["Status"]
      assert_equal ["410 Gone"], headers["status"]
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_response 410
      assert_response :gone
      assert_equal ["cookie_1=; path=/", "cookie_3=chocolate; path=/"], response.headers["Set-Cookie"]
=======
      assert_equal nil, response.headers["Set-Cookie"]
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_equal ["cookie_1=; path=/", "cookie_3=chocolate; path=/"], headers['set-cookie']
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_equal [
        CGI::Cookie::new("name" => "cookie_1", "value" => ""),
        CGI::Cookie::new("name" => "cookie_3", "value" => "chocolate")
      ], response.headers["cookie"]
=======
      assert_equal [[], ["chocolate"]], response.headers["cookie"]
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
      assert_equal [], headers["cookie"]
      assert_equal({"cookie_1"=>"", "cookie_2"=>"oatmeal", "cookie_3"=>"chocolate"}, cookies)
      assert_equal "Gone", response.body
    end
  end

<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
  def test_redirect
    with_test_route_set do
      get '/redirect'
      assert_equal 302, status
      assert_equal "Found", status_message
      assert_equal "302 Found", response.headers["Status"]
      assert_equal ["302 Found"], headers["status"]
      assert_response 302
      assert_response :redirect
      assert_response :found
      assert_equal "<html><body>You are being <a href=\"http://www.example.com/get\">redirected</a>.</body></html>", response.body
      assert_kind_of HTML::Document, html_document
      assert_equal 1, request_count
    end
  end

  def test_xml_http_request_get
    with_test_route_set do
      xhr :get, '/get'
      assert_equal 200, status
      assert_equal "OK", status_message
      assert_equal "200 OK", response.headers["Status"]
      assert_equal ["200 OK"], headers["status"]
      assert_response 200
      assert_response :success
      assert_response :ok
      assert_equal "JS OK", response.body
    end
  end

  def test_get_with_query_string
    with_test_route_set do
      get '/get_with_params?foo=bar'
      assert_equal '/get_with_params?foo=bar', request.env["REQUEST_URI"]
      assert_equal '/get_with_params?foo=bar', request.request_uri
      assert_equal nil, request.env["QUERY_STRING"]
      assert_equal 'foo=bar', request.query_string
      assert_equal 'bar', request.parameters['foo']

      assert_equal 200, status
      assert_equal "foo: bar", response.body
    end
  end

  def test_get_with_parameters
    with_test_route_set do
      get '/get_with_params', :foo => "bar"
      assert_equal '/get_with_params', request.env["REQUEST_URI"]
      assert_equal '/get_with_params', request.request_uri
      assert_equal 'foo=bar', request.env["QUERY_STRING"]
      assert_equal 'foo=bar', request.query_string
      assert_equal 'bar', request.parameters['foo']

      assert_equal 200, status
      assert_equal "foo: bar", response.body
    end
  end

=======
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
  private
    def with_test_route_set
      with_routing do |set|
        set.draw do |map|
          map.with_options :controller => "IntegrationProcessTest::Integration" do |c|
<<<<<<< HEAD:vendor/rails/actionpack/test/controller/integration_test.rb
            c.connect "/:action"
=======
            c.connect '/get', :action => "get"
            c.connect '/post', :action => "post"
            c.connect '/cookie_monster', :action => "cookie_monster"
>>>>>>> i18n:vendor/rails/actionpack/test/controller/integration_test.rb
          end
        end
        yield
      end
    end
end

end
