CounterController = {
    increment = function (self)
        self.session.value = self.session.value + self.params.increment
    end,
}
