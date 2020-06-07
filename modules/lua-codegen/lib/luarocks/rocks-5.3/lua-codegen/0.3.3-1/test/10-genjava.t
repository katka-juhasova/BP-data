#!/usr/bin/env lua

require 'Test.More'

plan(1)

local tmpl = dofile '../test/java.lua'

tmpl._name = 'Person'
tmpl._attrs = {
    { _name = 'name',       _type = 'String' },
    { _name = 'age',        _type = 'Integer' },
    { _name = 'address',    _type = 'String' },
}

is( tmpl 'class', [[
public class Person {
    private String name;
    private Integer age;
    private String address;

    public void setName(String name) {
        this.name = name;
    }
    public String getName() {
        return this.name;
    }

    public void setAge(Integer age) {
        this.age = age;
    }
    public Integer getAge() {
        return this.age;
    }

    public void setAddress(String address) {
        this.address = address;
    }
    public String getAddress() {
        return this.address;
    }
}
]], "Java getter/setter" )

