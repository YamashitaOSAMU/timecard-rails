class IssueGithub < Provider
  store_into :info do |a|
    issue_id
    html_url
    number
    assignee_avatar_url 
  end

  def issue
    Issue.find(self.provided_id)
  end

  def reopen(token)
    modify(token, {state: "open"})
  end

  def close(token)
    modify(token, {state: "close"})
  end

  def modify(token, params)
    options = {}
    options["title"] = params[:subject] if params[:subject]
    options["body"] = params[:description] if params[:description]
    options["state"] = params[:state] if params[:state]
    if params[:assignee_id].present?
      user = User.find(params[:assignee_id])
      options["assignee"] = user.github.username
    else
      options["assignee"] = nil
    end
    # FIXME full_nameを保存するときにスペースは取り除くべき
    fn = self.issue.project.github.full_name.gsub(/  /,"").split("/")
    issue = Provider.github(token).issues.edit(
      fn[0], fn[1], self.number, options
    )
  end

  def add_comment(token, params)
    # FIXME full_nameを保存するときにスペースは取り除くべき
    fn = self.issue.project.github.full_name.gsub(/  /,"").split("/")
    comment = Provider.github(token).issues.comments.create(
      fn[0], fn[1], self.number, body: params[:body]
    )
    return comment.body
  end
end
