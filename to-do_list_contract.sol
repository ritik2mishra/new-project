// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedTodoList {
    // Structure to represent a task
    struct Task {
        uint256 id;
        string content;
        bool completed;
        uint256 createdAt;
        address creator;
    }

    // Events to log task-related actions
    event TaskCreated(
        uint256 id, 
        string content, 
        bool completed, 
        uint256 createdAt, 
        address creator
    );
    event TaskCompleted(uint256 id, bool completed);
    event TaskDeleted(uint256 id);

    // Mapping to store tasks for each user
    mapping(address => Task[]) private userTasks;
    
    // Mapping to track total tasks per user
    mapping(address => uint256) public userTaskCount;

    // Modifier to check task ownership
    modifier onlyTaskOwner(uint256 _taskIndex) {
        require(_taskIndex < userTasks[msg.sender].length, "Task does not exist");
        _;
    }

    // Create a new task
    function createTask(string memory _content) public {
        require(bytes(_content).length > 0, "Task content cannot be empty");
        
        Task memory newTask = Task({
            id: userTaskCount[msg.sender],
            content: _content,
            completed: false,
            createdAt: block.timestamp,
            creator: msg.sender
        });

        userTasks[msg.sender].push(newTask);
        userTaskCount[msg.sender]++;

        emit TaskCreated(
            newTask.id, 
            newTask.content, 
            newTask.completed, 
            newTask.createdAt, 
            newTask.creator
        );
    }

    // Mark a task as completed
    function completeTask(uint256 _taskIndex) public onlyTaskOwner(_taskIndex) {
        Task storage task = userTasks[msg.sender][_taskIndex];
        require(!task.completed, "Task is already completed");
        
        task.completed = true;
        
        emit TaskCompleted(_taskIndex, true);
    }

    // Get all tasks for the calling user
    function getUserTasks() public view returns (Task[] memory) {
        return userTasks[msg.sender];
    }

    // Get a specific task by index
    function getTask(uint256 _taskIndex) public view onlyTaskOwner(_taskIndex) returns (Task memory) {
        return userTasks[msg.sender][_taskIndex];
    }

    // Get number of tasks for the calling user
    function getTaskCount() public view returns (uint256) {
        return userTaskCount[msg.sender];
    }

    // Delete a specific task
    function deleteTask(uint256 _taskIndex) public onlyTaskOwner(_taskIndex) {
        // Remove the task by replacing it with the last task and then reducing the array length
        Task[] storage tasks = userTasks[msg.sender];
        
        // Emit event before modifying the array
        emit TaskDeleted(_taskIndex);

        // Replace the task to be deleted with the last task
        tasks[_taskIndex] = tasks[tasks.length - 1];
        
        // Remove the last task
        tasks.pop();

        // Decrement the task count
        userTaskCount[msg.sender]--;
    }

    // Get incomplete tasks
    function getIncompleteTasks() public view returns (Task[] memory) {
        Task[] memory allTasks = userTasks[msg.sender];
        uint256 incompleteTasks = 0;

        // First, count incomplete tasks
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (!allTasks[i].completed) {
                incompleteTasks++;
            }
        }

        // Create array to store incomplete tasks
        Task[] memory incompleteTaskList = new Task[](incompleteTasks);
        uint256 counter = 0;

        // Populate incomplete tasks
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (!allTasks[i].completed) {
                incompleteTaskList[counter] = allTasks[i];
                counter++;
            }
        }

        return incompleteTaskList;
    }

    // Search tasks by content
    function searchTasks(string memory _searchTerm) public view returns (Task[] memory) {
        Task[] memory allTasks = userTasks[msg.sender];
        uint256 matchingTasks = 0;

        // First, count matching tasks
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (containsSubstring(allTasks[i].content, _searchTerm)) {
                matchingTasks++;
            }
        }

        // Create array to store matching tasks
        Task[] memory matchingTaskList = new Task[](matchingTasks);
        uint256 counter = 0;

        // Populate matching tasks
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (containsSubstring(allTasks[i].content, _searchTerm)) {
                matchingTaskList[counter] = allTasks[i];
                counter++;
            }
        }

        return matchingTaskList;
    }

    // Helper function to check if a string contains a substring (case-insensitive)
    function containsSubstring(string memory _string, string memory _substring) internal pure returns (bool) {
        bytes memory stringBytes = bytes(_string);
        bytes memory substringBytes = bytes(_substring);

        // If substring is empty, return false
        if (substringBytes.length == 0) return false;

        // Convert both to lowercase for case-insensitive search
        string memory lowercaseString = _toLowerCase(_string);
        string memory lowercaseSubstring = _toLowerCase(_substring);

        return keccak256( bytes(lowercaseString)).length >= keccak256( bytes(lowercaseSubstring)).length &&
               _indexOf(lowercaseString, lowercaseSubstring) != -1;
    }

    // Helper function to convert string to lowercase
    function _toLowerCase(string memory _str) internal pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);
        
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    // Helper function to find substring index
    function _indexOf(string memory _haystack, string memory _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        
        if (h.length < n.length) return -1;
        
        bool matching;
        for (uint i = 0; i <= h.length - n.length; i++) {
            matching = true;
            for (uint j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    matching = false;
                    break;
                }
            }
            if (matching) return int(i);
        }
        
        return -1;
    }
}