require 'spec_helper'

describe AdvancedSearchController do

  before do
    fake_login
  end

  context 'new search' do

    it "should construct empty criteria objects for new search" do
      SearchCriteria.stub(:new).and_return("empty_criteria")
      get :new
      response.should render_template('index')
      assigns[:criteria_list].should == ["empty_criteria"]
    end

  end

  context 'search' do

    before do
      SearchService.stub(:search).and_return([])
      :criteria_list
    end

    it "should show list of enabled forms" do
      FormSection.stub(:by_order).and_return :some_forms
      get :index
      assigns[:forms].should == :some_forms
    end

    it "should perform a search using the parameters passed to it for admin users" do
      fake_admin_login
      search = mock("search_criteria")
      SearchCriteria.stub!(:build_from_params).and_return([search])
      fake_results = [:fake_child, :fake_child]
      SearchService.should_receive(:search).with(2, [search]).and_return(fake_results)
      
      get :index, :page => 2, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_by_value => nil
      
      assigns[:results].should == fake_results
    end

    it "should append created_by as self for limited users" do
      search = mock("search_criteria")
      SearchCriteria.stub!(:build_from_params).and_return([search])
      stub_results = [:created_by, :created_by_value, :disable_create]
      created_by = mock("created_by")
      SearchFilter.should_receive(:new).with({:value=>"fakeuser", :join=>"AND", :field=>"created_by", :index=>1, :field2=>"created_by_full_name"}).and_return(created_by)
      SearchService.should_receive(:search).with(1, [search,created_by]).and_return(stub_results)

      get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_by_value => nil
      
      assigns[:results].should == stub_results
    end

    it "should construct criteria objects for advanced child search for admin" do
      fake_admin_login
      SearchCriteria.stub(:build_from_params).and_return(["criteria_list"])
      get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_by_value => nil
      assigns[:criteria_list].should == ["criteria_list"]
    end

    it "should construct criteria objects for advanced child search for limited access users" do
      SearchCriteria.stub(:build_from_params).and_return(["criteria_list"])
      created_by_mock = mock("Created_by")
      SearchFilter.should_receive(:new).with({:value=>"fakeuser", :join=>"AND", :field=>"created_by", :index=>1, :field2=>"created_by_full_name"}).and_return(created_by_mock)
      get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_by_value => nil
      assigns[:criteria_list].should include "criteria_list"
      assigns[:criteria_list].should include created_by_mock
    end

    context 'search filters' do

      it "should append search filter 'created_by' to the list of search criteria for admin" do
        fake_admin_login
        SearchCriteria.stub(:build_from_params).and_return([])
        SearchFilter.should_receive(:new).with({:field => "created_by", :field2 => "created_by_full_name", :value => "johnny_user", :join => 'AND', :index => 1}).and_return("created_by_filter")
        get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_by_value => "johnny_user"
        assigns[:criteria_list].should include("created_by_filter")
      end

      it "should append search filter 'updated_by' to the list of search criteria" do
        SearchCriteria.stub(:build_from_params).and_return([])
        SearchFilter.should_receive(:new).with({:value=>"fakeuser", :join=>"AND", :field=>"created_by", :index=>1, :field2=>"created_by_full_name"}).and_return("created_by")
        SearchFilter.should_receive(:new).with({:field => "last_updated_by", :field2 => "last_updated_by_full_name", :value => "johnny_user", :join => 'AND', :index => 2}).and_return("updated_by_filter")
        get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :updated_by_value => "johnny_user"
        assigns[:criteria_list].should include("updated_by_filter")
      end

      it "should append search range 'created_at' to the list of search criteria" do
        SearchCriteria.stub(:build_from_params).and_return(["criteria_list"])
        SearchDateFilter.should_receive(:new).with({:field => "created_at", :from_value => "2012-04-23T00:00:00Z", :to_value => "2012-04-25T00:00:00Z", :join => 'AND', :index => 1}).and_return("created_at_range")
        get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_at_after_value => "2012-04-23", :created_at_before_value => "2012-04-25"
        assigns[:criteria_list].should include("created_at_range")
      end

      it "should append search range 'updated_at' to the list of search criteria" do
        SearchCriteria.stub(:build_from_params).and_return(["criteria_list"])
        SearchDateFilter.should_receive(:new).with({:field => "last_updated_at", :from_value => "2012-04-23T00:00:00Z", :to_value => "2012-04-25T00:00:00Z", :join => 'AND', :index => 2}).and_return("updated_at_range")
        get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :updated_at_after_value => "2012-04-23", :updated_at_before_value => "2012-04-25"
        assigns[:criteria_list].should include("updated_at_range")
      end

      it "should append search filter 'created_by_organisation' to the list of search criteria for admin" do
        fake_admin_login
        SearchCriteria.stub(:build_from_params).and_return([])
        SearchFilter.should_receive(:new).with({:field => "created_organisation", :value => "STC", :join => 'AND', :index => 1}).and_return("created_by_organisation_filter")
        get :index, :criteria_list => {"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}, :created_by_organisation_value => "STC"
        assigns[:criteria_list].should include("created_by_organisation_filter")
      end
    end

  end

  context 'constructor' do

    let(:controller) { AdvancedSearchController.new }

    it "should say child fields have been selected" do
      controller.child_fields_selected?({"0" => {"field" => "name_of_child", "value" => "joe joe", "index" => "0"}}).should == true
    end

    it "should say child fields have NOT been selected" do
      controller.child_fields_selected?({"0" => {"field" => "", "value" => "", "index" => "0"}}).should == false
    end

  end

end