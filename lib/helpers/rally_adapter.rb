require 'rally_api'
require 'time'

module Rally_Metrics
  class RallyAdapter
    attr_reader :rally, :headers, :base_url, :workspace_ref, :project_ref, :api_version, :workspace_name, :project_name

    # Version of this RallyAdapter class.
    def self.version
      "1.0.0"
    end

    # Creates a new instance of this class
    # @param [String] username Reburied: User name used to access Rally.
    # @param [String] password Reburied: Password used to access Rally.
    # @param [String] workspace Reburied: The Rally workspace name.
    # @param [String] project Reburied: The Rally project name.
    # @param [String] base_url The Rally API base url to use when making rest calls.  If this is nil 'https://rally1.rallydev.com/slm' is used.
    # @param [String] api_version The Rally API version to call.  If this is nil 1.33 is used.
    # @param [RallyAPI::CustomHttpHeader] headers RallyAPI::CustomHttpHeader object you wish to use.  If this is nil
    #  a default RallyAPI::CustomHttpHeader object will be used.
    def initialize(username, password, workspace, project, year, base_url = nil, api_version = nil, headers = nil)
      raise ArgumentError, "username is required"  if username.nil?  or username.empty?
      raise ArgumentError, "password is required"  if password.nil?  or password.empty?
      raise ArgumentError, "workspace is required" if workspace.nil? or workspace.empty?
      raise ArgumentError, "project is required"   if project.nil?   or project.empty?
      raise ArgumentError, "year is required"      if year.nil?      or year.empty?

      # Set the base url to the input.  if the input is nil then we default.
      @base_url = base_url
      @base_url ||= "https://rally1.rallydev.com/slm"

      @api_version = api_version
      @api_version ||= "1.33"

      # Create the headers if they are not passed.
      @headers = headers
      @headers ||= begin
        @headers = RallyAPI::CustomHttpHeader.new()
        @headers.name = "FixMe"
        @headers.vendor = "FixMe"
        @headers.version = RallyAdapter.version
      end

      @rally = RallyAPI::RallyRestJson.new({ :base_url => @base_url, :username => username, :password => password,
                                             :headers => headers, :version => @api_version })

      # Get the workspace ref and project ref.  These are needed for all
      # rally quarries.
      @workspace_name = workspace
      @workspace_ref = @rally.find_workspace(@workspace_name)

      @project_name = project
      @project_ref   = @rally.find_project(@workspace_ref, @project_name)

      # This is used to find all iterations for the current year
      @year = "S#{year}-"
    end


    # Custom query to find all iterations for a year.
    def get_iterations()
      results = @rally.find(make_query(:iteration, "((Name contains #{@year}) AND (State != \"Planning\"))"))
      nil if results.count < 1
      results
    end


    # Gets the iteration based on the date.  If no date
    # passed the current date is used and you will get the current iteration
    # @param [Time] Time object that describes when the iteration is scheduled.  If this is not passed Time.now is used.
    # @return [RallyAPI::RallyObject] RallyAPI::RallyObject that describes a Rally Iteration.
    #  It will contain the Name and _ref fields.  If you need more detail call .read on this object.
    # @see [RallyAPI::RallyObject]
    def get_iteration(time = Time.now)
      results = @rally.find(make_query(:iteration, "((StartDate <= \"#{time.iso8601}\") AND (EndDate >= \"#{time.iso8601}\"))"))
      nil if results.count < 1
      results.first
    end


    # Method to get stories or bugs.  Really any HierarchicalRequirement object.
    # @param [String] query The query used to fetch the story. "(State = \"Closed\")" or
    #  "((StartDate < \"#{time.iso8601}\") AND (EndDate > \"#{time.iso8601}\"))", "Name,_ref")) or
    #  '(IpCenterTicket != "")'   Double quotes are reburied in the query.
    # @param [Array] extra_fields Extra fields you want selected.  By default Name and IpCenterTicket are fetched.
    # @return [RallyAPI::RallyObject]  The Rally HierarchicalRequirement object.
    # @see [RallyAPI::RallyObject]
    def get_stories(type, query, extra_fields = nil)
      extra_fields ||= []
      extra_fields << "Name" unless extra_fields.include? "Name"
      @rally.find(make_query(type, query, extra_fields))
    end


    # Gets a user info with DisplayName, EmailAddress, UserName, FirstName, LastName loaded.
    # @param [String] user_name
    # @return [RallyAPI::RallyObject] The user object.  You can call .read if you need more info.
    def get_user(user_name)
      @rally.find(make_query(:user, "(UserName = \"#{user_name}\")", ["DisplayName","EmailAddress","UserName","FirstName","LastName"]))
    end


    # Method to create a default RallyAPI::RallyQuery object.  You can change the
    # defaults it sets if you like.  This just makes things go faster.
    # @param [Symbol] type  The Rally object type you want to query.
    # @param [String] query_string The query string.   This must be in parenthesises and all values MUST be in double
    #  quito's.  This is a rally api requirement.  Like this: "(State = \"Closed\")" or
    #  "((StartDate < \"#{time.iso8601}\") AND (EndDate > \"#{time.iso8601}\"))"
    # @param [Array] fetch An array of field names to fetch.  For example ["Name", "CreationDate"]
    #   Passing this fetch list is what makes this API extremely fast.  You can also call .read on the RallyAPI::RallyObject
    #   that is returned for all quires and it will fully hydrate the object (lazy load).
    #   if you do not pass this param then it defaults to ["Name"]
    # @param [String] order The sort order.  For example: Name Asc.  If not passed this will default to Name Asc
    def make_query(type, query_string, fetch = ["Name"], order = "Name Asc")
      query = RallyAPI::RallyQuery.new()
      query.type = type
      query.query_string = query_string
      query.fetch = fetch.join(",")
      query.workspace = @workspace_ref
      query.project = @project_ref
      query.page_size = 2000       #optional - default is 2000
      query.limit = 1000          #optional - default is 99999
      query.project_scope_up = false
      query.project_scope_down = true
      query.order = order
      query
    end
  end
end
