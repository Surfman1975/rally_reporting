module Rally_Metrics
  class App < Sinatra::Base

    get '/' do
      haml :index
    end

    get '/metrics/:workspace/:project/:year'do
      workspace = params[:workspace]
      project   = params[:project  ]
      year      = params[:year     ]

      results  = Rally_Metrics::Model::RallyQuery.find_iterations(workspace, project, year)
      bargraph = Rally_Metrics::Model::RallyQuery.create_bargraph(results[:dvl_totals],results[:bau_totals],results[:brkfx_totals],results[:iterations],results[:estimate_totals],results[:tst_totals])
      sparkline_dvl   = Rally_Metrics::Model::RallyQuery.create_sparkline_code(results[:dvl_totals], "", 275)
      sparkline_bau   = Rally_Metrics::Model::RallyQuery.create_sparkline_code(results[:bau_totals], "", 25)
      sparkline_brkfx = Rally_Metrics::Model::RallyQuery.create_sparkline_code(results[:brkfx_totals], "", 10)
      #sparkline_tst   = Rally_Metrics::Model::RallyQuery.create_sparkline_code(results[:tst_totals], "", 30)
      act_vs_est      = Rally_Metrics::Model::RallyQuery.get_loe_vs_actual_pct(results[:dvl_totals],results[:estimate_totals])
      sparklink_act_vs_est = Rally_Metrics::Model::RallyQuery.create_sparkline_code(act_vs_est, "", 10) 

      haml(:metrics, :format => :xhtml, :escape_html => 'true',
          :locals => { :bargraph => bargraph,
                       :sparkline_dvl  => sparkline_dvl,
                       :sparkline_bau  => sparkline_bau,
                       :sparkline_brkfx => sparkline_brkfx,
                       :act_vs_est     => act_vs_est,
                       :sparklink_act_vs_est => sparklink_act_vs_est
                     }
          )
    end
  end
end
