class CommentsController < ApplicationController
  before_action :set_issue, only: [:create]
  before_action :set_comment, only: [:update, :destroy]
  before_action :require_member

  # POST /comments
  # POST /comments.json
  def create
    @comment = @issue.comments.build(comment_params)
    @comment.user_id = current_user.id

    respond_to do |format|
      if @comment.save
        if @comment.issue.project.github && current_user.github
          comment = @comment.issue.github.add_comment(current_user.github.oauth_token , comment_params)
          if comment
            @comment.add_github(comment.id)
          else
            flash[:alert] = 'Create a new comment to Github failed.' + @comment.errors.full_messages.join("\n")
            format.html { render action: 'new' }
          end
        end
        format.html { redirect_to @issue, notice: 'Comment was successfully created.' }
        format.json { render action: 'show', status: :created, location: @comment }
      else
        format.html { redirect_to @issue, alert: 'Comment was failed created.' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /comments
  # PATCH /comments.json
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        if @comment.github && @comment.github.comment_id && current_user.github
          comment = @comment.github.modify(
            current_user.github.oauth_token, comment_params
          )
          unless comment
            flash[:alert] = 'Update a new comment to Github failed.' + @comment.errors.full_messages.join("\n")
            format.html { redirect_to @comment, notice: 'Issue was successfully updated.' }
          end
        end
        format.html { redirect_to @comment.issue, notice: 'Comment was successfully updated.' }
        format.json { render action: 'show', status: :created, location: @comment }
      else
        format.html { redirect_to @comment.issue, alert: 'Comment was failed updated.' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    if @comment.github && @comment.github.comment_id && current_user.github
      comment = @comment.github.destroy(
        current_user.github.oauth_token
      )
    end
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to @comment.issue }
      format.json { head :no_content }
    end
  end

  private

  def set_issue
    @issue = Issue.find(params[:issue_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def require_member
    project = @issue ? @issue.project : @comment.issue.project
    redirect_to root_path, alert: "You are not project member." unless project.member?(current_user)
  end
end
