require_relative "patch"

class RunnerError < StandardError
end


class Task
  @@id = 0
  attr_accessor :task_id, :task_desc, :task_block
  def initialize(task_desc, task_block)
    @@id = @@id + 1
    @task_id = @@id
    @task_desc = task_desc
    @task_block = task_block
  end
end

class Runner
  def initialize(&block)
    @current_task = nil
    @tasks = []
    init_platform
    instance_eval(&block)
    self
  end

  def init_platform
    @macos_arch, _ = RUBY_PLATFORM.split("-") # x86_64-darwin21, arm64-darwin21 => x86_64, arm64
  end

  def task(task_desc, &block)
    @tasks << Task.new(task_desc, block)
  end

  def sh(command_text)
    result = system(command_text)
    if result
      on_success(command_text)
    else
      on_fail(command_text)
      raise RunnerError
    end
  end

  def on_success(command_text = nil)
    puts "[success] task@#{@current_task.task_id} shell: #{command_text}".green
  end

  def on_fail(command_text = nil)
    puts "[fail] task@#{@current_task.task_id} shell: #{command_text}".yellow
  end

  def run
    @tasks.each do |task|
      @current_task = task
      blk = @current_task.task_block
      puts "#{"-"* 20}".green
      puts "[start task@#{@current_task.task_id}] #{@current_task.task_desc}".green
      instance_eval(&blk)
      puts "[finished task@#{@current_task.task_id}]".green
      @current_task = nil
    end
  end
end
