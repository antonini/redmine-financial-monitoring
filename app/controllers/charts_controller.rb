class ChartsController < ApplicationController
  unloadable

  before_filter :find_project, :authorize, :only => :index

  def index
    
    @project = Project.find_by_identifier(params['project_id']) 
    @charts_settings = DayPerProject.find_by(project_id: @project.id)
    
    ids = @project.self_and_descendants.collect(&:id).join(",");
    

    #@issues = Issue.where("project_id = :project_id", { project_id: project.id })
    connection = ActiveRecord::Base.connection
    query = "SELECT \
      YEAR(GREATEST(start_date,created_on)), MONTH(GREATEST(start_date,created_on)), ROUND(sum(estimated_hours)) \
      FROM issues \
      WHERE project_id in (#{ids}) AND estimated_hours is not null ";
    
    if @charts_settings.start_date != nil
      query += "AND GREATEST(start_date,created_on) > '#{@charts_settings.start_date}' "
    end
    if @charts_settings.included_status != nil && @charts_settings.included_status != ''
      query += "AND status_id IN (#{@charts_settings.included_status.split(";").join(",")}) "
    end
    
    query += "GROUP BY YEAR(GREATEST(start_date,created_on)), MONTH(GREATEST(start_date,created_on)) \
      ORDER BY YEAR(GREATEST(start_date,created_on)), MONTH(GREATEST(start_date,created_on))"
    
    @stats = connection.execute(query) 
    

  end

  def manage
    @charts_settings = DayPerProject.find_by(project_id: params['day_per_project']['project_id'])
    
    if params['day_per_project']["included_status_ids"].to_s.blank? then
      params['day_per_project']["included_status"] = ""
    else 
      params['day_per_project']["included_status"] = params['day_per_project']["included_status_ids"].join(';')
    end
    
    @charts_settings.update(day_per_project_params)
    redirect_to :back
  end

  def day_per_project_params
    params.require(:day_per_project).permit(:project_id, :day, :start_date, :included_status)
  end  

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end