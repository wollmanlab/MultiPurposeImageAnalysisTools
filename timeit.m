function t = timeit(f)
%TIMEIT Measure time required to run function.
%   T = TIMEIT(F) measures the time (in seconds) required to run 
%   F, which is a function handle.  
%
%   If nargout(F) == 0, TIMEIT calls F with no output arguments,
%   like this:
%
%       F()
%
%   If nargout(F) > 0, TIMEIT calls F with a single output argument, like this:
%
%       OUT = F()
%
%   If nargout(F) < 0, which can occur when F uses varargout or is an
%   anonymous function, TIMEIT uses try/catch to determine whether to call F
%   with one or zero output arguments.
%
%   TIMEIT handles automatically the usual benchmarking
%   procedures of "warming up" F, figuring out how many times to
%   repeat F in a timing loop, etc.  TIMEIT uses a median to form
%   a reasonably robust time estimate.
%
%   Note: The computed time estimate is less accurate when the
%   time required to call F is on the same order as the
%   function-handle calling overhead.  On a 2GHz laptop running
%   R2007b, the function-handle calling overhead is roughly 5e-6
%   seconds. Therefore, it recommended that benchmark problems be
%   constructed so that calling F() requires 1e-4 seconds or
%   longer.
%
%   Examples
%   --------
%   How much time does it take to compute sum(A.' .* B, 1), where
%   A is 12000-by-400 and B is 400-by-12000?
%
%       A = rand(12000, 400);
%       B = rand(400, 12000);
%       f = @() sum(A.' .* B, 1);
%       timeit(f)
%
%   How much time does it take to dilate the text.png image with
%   a 25-by-25 all-ones structuring element?
%
%       bw = imread('text.png');
%       se = strel(ones(25, 25));
%       g = @() imdilate(bw, se);
%       timeit(g)
%

%   Steve Eddins
%   $Revision: 1.4 $  $Date: 2008/02/17 22:06:01 $

t_rough = roughEstimate(f);
% roughEstimate() takes care of warming up f().

% Calculate the number of inner-loop repetitions so that 
% the inner for-loop takes at least about 10ms to execute.
desired_inner_loop_time = 0.01;
num_inner_iterations = max(ceil(desired_inner_loop_time / t_rough), 1);

% Calculate the number of outer-loop repetitions so that the
% outer for-loop takes at least about 1s to execute.  The outer
% loop should execute at least 10 times.
desired_outer_loop_time = 1;
inner_loop_time = num_inner_iterations * t_rough;
min_outer_loop_iterations = 10;
num_outer_iterations = max(ceil(desired_outer_loop_time / inner_loop_time), ...
    min_outer_loop_iterations);

% Get the array of output arguments to be used on the left-hand
% side when calling f.
outputs = outputArray(f);

times = zeros(num_outer_iterations, 1);
for k = 1:num_outer_iterations
    t1 = tic;
    for p = 1:num_inner_iterations
        [outputs{:}] = f(); 
    end
    times(k) = toc(t1);
end

t = median(times) / num_inner_iterations;

function t = roughEstimate(f)
%   Return rough estimate of time required for one execution of
%   f().  Basic warmups are done, but no fancy looping, medians,
%   etc.

% Get the array of output arguments to be used on the left-hand
% side when calling f.
outputs = outputArray(f);

% Warm up f().
[outputs{:}] = f(); 
[outputs{:}] = f(); 

% Warm up tic/toc.
t1 = tic();
elapsed = toc(t1); %#ok<NASGU>

counter = 0;
t1 = tic;
while toc(t1) < 0.01
    [outputs{:}] = f(); 
    counter = counter + 1;
end
t = toc(t1) / counter;

function outputs = outputArray(f)
%   Return a cell array to be used as the output arguments when calling f.  
%   * If nargout(f) > 0, return a 1-by-1 cell array so that f is called with
%     one output argument.
%   * If nargout(f) == 0, return a 1-by-0 cell array so that f will be called
%     with zero output arguments.
%   * If nargout(f) < 0, use try/catch to determine whether to call f with one
%     or zero output arguments.
%     Note: It is not documented (as of R2008b) that nargout can return -1.
%     However, it appears to do so for functions that use varargout and for
%     anonymous function handles.  

num_f_outputs = nargout(f);
if num_f_outputs < 0
   try
      a = f();
      % If the line above doesn't throw an error, then it's OK to call f() with
      % one output argument.
      num_f_outputs = 1;
      
   catch %#ok<CTCH>
      % If we get here, assume it's because f() has zero output arguments.  In
      % recent versions of MATLAB we could catch the specific exception ID
      % MATLAB:maxlhs, but that would limit the use of timeit to MATLAB versions
      % since the introduction of MExceptions.
      num_f_outputs = 0;
   end
end

if num_f_outputs > 0
   outputs = cell(1, 1);
else
   outputs = cell(1, 0);
end

