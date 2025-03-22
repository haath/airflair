package cli;

import haxe.Json;
import sys.thread.Thread;
import util.ApiRequest;


class ThreadPool
{
    final threads: Array<Thread>;
    var curIndex: Int;

    var tasks: Array<Array<ApiRequest>>;

    public function new(nofThreads: Int, preliminary: Bool)
    {
        curIndex = 0;
        tasks = [ for (_ in 0...nofThreads) [ ] ];

        threads = [ for (_ in 0...nofThreads) Thread.create(() -> threadWorker(preliminary)) ];
        for (thread in threads)
        {
            thread.sendMessage(Thread.current());
        }
    }

    public function add(req: ApiRequest)
    {
        tasks[ curIndex ].push(req);

        curIndex = (curIndex + 1) % threads.length;
    }

    public function collect(): Array<Dynamic>
    {
        var progress: ProgressBar = new ProgressBar('fetching flights');

        // distribute tasks
        var nofTasks: Int = 0;
        for (i in 0...threads.length)
        {
            var tasks: Array<ApiRequest> = tasks.pop();
            nofTasks += tasks.length;
            threads[ i ].sendMessage(tasks);

            progress.print(0.025 * ((i + 1) / threads.length));
        }
        tasks = [ for (_ in 0...threads.length) [ ] ];

        // collect responses
        var responses: Array<Dynamic> = [ ];
        var tasksCompleted: Int = 0;
        while (tasksCompleted < nofTasks)
        {
            var resp: Null<Dynamic> = Thread.readMessage(true);
            if (resp == null)
            {
                throw 'unexpected null response';
            }
            responses.push(resp);

            tasksCompleted++;

            progress.print(0.025 + 0.975 * (tasksCompleted / nofTasks));
        }

        progress.done();

        return responses;
    }

    public function stop()
    {
        for (thread in threads)
        {
            thread.sendMessage(null);
        }

        for (_ in threads)
        {
            Thread.readMessage(true);
        }
    }

    static function threadWorker(acceptIncomplete: Bool)
    {
        var parent: Thread = Thread.readMessage(true);

        while (true)
        {
            var tasks: Null<Array<ApiRequest>> = Thread.readMessage(true);
            if (tasks == null)
            {
                break;
            }

            var incomplete: Array<Int> = [ ];

            for (i in 0...tasks.length)
            {
                var task: ApiRequest = tasks[ i ];

                var success: Bool = doTask(parent, task, acceptIncomplete);

                if (!success)
                {
                    incomplete.push(i);
                }
            }


            for (incompleteIdx in incomplete)
            {
                var task: ApiRequest = tasks[ incompleteIdx ];
                var attempts: Int = 20;

                while (attempts >= 1)
                {
                    var success: Bool = doTask(parent, task, attempts == 1);
                    if (success)
                    {
                        break;
                    }

                    Sys.sleep(0.5);
                    attempts--;
                }

                if (attempts == 0)
                {
                    throw 'something went wrong';
                }
            }
        }

        parent.sendMessage(null);
    }

    static function doTask(parent: Thread, task: ApiRequest, acceptIncomplete: Bool): Bool
    {
        var respStr: Null<String> = null;
        try
        {
            respStr = task.send();
        }
        catch (ex: Any)
        {
            return false;
        }

        var respObj: Dynamic = Json.parse(respStr);

        if (Reflect.hasField(respObj, 'incomplete') && (respObj.incomplete == true) && !acceptIncomplete)
        {
            return false;
        }
        if (Reflect.hasField(respObj, 'success') && (respObj.success == false))
        {
            switch (respObj.message)
            {
                case 'Invalid value for from.':
                    Sys.println('skiplagged error: invalid origin airport');

                case 'Invalid value for to.':
                    Sys.println('skiplagged error: invalid destination airport');

                default:
                    Sys.println('skiplagged error: ${respObj.message}');
            }
            Sys.print('req url: ${task.getUrl()}');
            Sys.exit(-5);
        }

        parent.sendMessage(respObj);
        return true;
    }
}
