require 'rally_api'
require 'date'
#require 'debugger'

module Rally_Metrics
  module Model

    class RallyQuery

      def self.find_iterations(workspace, project, year)
        # Connection Defaults
        @user_name        = 'FixMe'
        @password         = 'FixMe!'
        @workspace_name   = workspace
        @project_name     = project
        @base_url         = "https://rally1.rallydev.com/slm"
        @api_version      = "1.33"
        @date             = Date.jd( DateTime.now.jd )
        @year             = year

        @rally_adapter = RallyAdapter.new( @user_name, @password, @workspace_name, @project_name, @year )

        # Find all iterations for the year 2013
        query_result = @rally_adapter.get_iterations()

        # Find current iteration
        @iteration = @rally_adapter.get_iteration( @date )

        iterations = Array.new
        bau_totals = Array.new
        dvl_totals = Array.new
        brkfx_totals = Array.new
        estimate_totals = Array.new
        tst_totals = Array.new
        act_vs_est = Array.new

        # loop through the iteration
        it = 0
        query_result.each do |iteration|
          iterations[it] = iteration.Name.sub(@year,'')

          bau = 0
          brkfx = 0
          dvl = 0
          est = 0
          tst = 0

          # Public: Find all BAU, BRKFX, TEST, and DEV user_stories for the current year.
          # Add up the Actual Time Spent for each story type per iteration.
          #
          # Returns Hash
          qr = @rally_adapter.get_stories(:hierarchicalrequirement, "( Iteration = #{iteration} )", ["Iteration","TaskActualTotal","TaskEstimateTotal"])
          qr.each do |story|
            if story.Name.include?('BAU')
              bau += story.TaskActualTotal.to_f
            elsif story.Name.include?('Break Fix')
              brkfx += story.TaskActualTotal.to_f
            else
              dvl += story.TaskActualTotal.to_f
            end
            est += story.TaskEstimateTotal.to_f
          end

          bau_totals[it]   = bau
          brkfx_totals[it] = brkfx
          tst_totals[it]   = tst
          dvl_totals[it]   = dvl
          estimate_totals[it] = est
          it += 1
        end
        return {:bau_totals => bau_totals, :brkfx_totals => brkfx_totals, :tst_totals => tst_totals, :dvl_totals => dvl_totals, :estimate_totals => estimate_totals, :iterations => iterations}
      end

      def self.normalize_array(ur_array)
        # the arrays must be normal
        min_val = ur_array.min()
        max_val = ur_array.max()
        sz = ur_array.size - 1

        ret_str = ""
        old = ""

        # normalize each value of the array
        for i in (0.. sz)
          old += ur_array[i].to_s + ","
          value_1 = (ur_array[i] - min_val)
          value_2 = (max_val - min_val)
          next if ( value_2 == 0 )
          new_val = ( ( value_1 / value_2 ) * 100).round
          ret_str += new_val.to_s + ","
        end
        return ret_str.chop
      end

      def self.get_mean(ur_array, mean)
        min_val = ur_array.min()
        max_val = ur_array.max()
        val = ( (mean - min_val)/(max_val - min_val) )

        if val > 1 
          val = 1
        end
        return "%.2f" % val
      end

      # Public: Create a google chart for total hours devoted to devlopment/bau/brkfx/test for the year.
      #
      # Examples
      #
      #   /metrics/FixMe/FixMe
      #
      # Returns Sparkline Chart
      def self.create_sparkline_code(ur_array, title, avg)
        cht = "lc"
        chs = "180x60"
        chco ="336699"
        chls = "1,1,0"
        chm = "h,CCCCCC,0," + get_mean(ur_array, avg) + ",8,-1|o,990000,0," + (ur_array.size - 1).to_s + ",4"
        chxt = "r,x,y"
        chxs = "0,990000,11,0,_|1,990000,1,0,_|2,990000,1,0,_"
        chxl = "0:|" + ur_array[ur_array.size-1].round.to_s + "|1:||2:||"
        chxp = "0," + ur_array[ur_array.size-1].to_s
        chd = "t:" + normalize_array(ur_array)
        chxp = chd.split(',')
        chxp = chxp[chxp.size-1]
        chxp = "0," + chxp

        return "http://chart.apis.google.com/chart?cht=#{cht}&chtt=#{title}&chs=#{chs}&chd=#{chd}&chco=#{chco}&chls=#{chls}&chm=#{chm}&chxt=#{chxt}&chxs=#{chxs}&chxl=#{chxl}&chxp=#{chxp}"
      end

      def self.get_sum(dvl, bau, brkfx)
         ( (dvl.inject(:+)/dvl.size) + (bau.inject(:+)/bau.size) + (brkfx.inject(:+)/brkfx.size) ).round
      end


      # Public: Create a google chart for total hours in each iteration for the year.
      #
      # Examples
      #
      #   /metrics/FixMe/FixMe
      #
      # Returns Bargraph
      def self.create_bargraph(dvl, bau, estimate, iterations, brkfx, tst)
        cht  = "bvs"
        chs  = "850x350"
        chxt = "x,y,r"
        chxr = "1,0," + get_sum(dvl, bau, brkfx).to_s + ",50|2,0," + get_sum(dvl, bau, brkfx).to_s + ",50"
          if @iteration.Name.include?(@year)
            chtt = "Hours%20Per%20Iteration%20(#{@year})|Current%20Iteration%20#{@iteration.Name}"
          else
            chtt = "Hours%20Per%20Iteration%20(#{@year})"
          end
        chts = "0000CC,15"
        chdl = "DEVL|BAU|BRKFX|Total%20Estimate"
        chco = "003366,0066CC,99CCFF,990000"
        chbh = "10,20,20"
        chf  = "c,s,FFFFFF"
        chxl = "0:" + "|" + iterations.join('|')
        chds = "0," + (get_sum(dvl, bau, brkfx )+ 200).to_s
        chd  = "t3:" + dvl.join(',') + "|" + bau.join(',') + "|" + estimate.join(',') + "|" + brkfx.join(',')
        chm  = "D,990000,3,0,3"

        return "http://chart.apis.google.com/chart?cht=#{cht}&chs=#{chs}&chxt=#{chxt}&chxr=#{chxr}&chtt=#{chtt}&chts=#{chts}&chdl=#{chdl}&chco=#{chco}&chbh=#{chbh}&chf=#{chf}&chxl=#{chxl}&chds=#{chds}&chd=#{chd}&chm=#{chm}"
      end

      def self.get_loe_vs_actual_pct(act, est)
        var = Array.new
        sz = act.size - 1

        for i in (0.. sz)
          if act[i] && est[i] == 0
            var[i] = 0
          else
            var[i] = ( (act[i]-est[i])/(act[i]+est[i]) )*100
          end
        end
        return var
      end
    end
  end
end