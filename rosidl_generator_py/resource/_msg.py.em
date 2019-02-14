@# Included from rosidl_generator_py/resource/_idl.py.em
@{

from rosidl_cmake import convert_camel_case_to_lower_case_underscore
from rosidl_generator_py.generate_py_impl import constant_value_to_py
from rosidl_generator_py.generate_py_impl import get_python_type
from rosidl_generator_py.generate_py_impl import value_to_py
from rosidl_parser.definition import Array
from rosidl_parser.definition import BasicType
from rosidl_parser.definition import BaseString
from rosidl_parser.definition import BoundedSequence
from rosidl_parser.definition import NamespacedType
from rosidl_parser.definition import NestedType
from rosidl_parser.definition import Sequence
from rosidl_parser.definition import String
from rosidl_parser.definition import WString
}@


class Metaclass_@(message.structure.type.name)(type):
    """Metaclass of message '@(message.structure.type.name)'."""

    _CREATE_ROS_MESSAGE = None
    _CONVERT_FROM_PY = None
    _CONVERT_TO_PY = None
    _DESTROY_ROS_MESSAGE = None
    _TYPE_SUPPORT = None

    __constants = {
@[for constant in message.constants.values()]@
        '@(constant.name)': @constant_value_to_py(constant.type, constant.value),
@[end for]@
    }

    @@classmethod
    def __import_type_support__(cls):
        try:
            from rosidl_generator_py import import_type_support
            module = import_type_support('@(package_name)')
        except ImportError:
            import logging
            import traceback
            logger = logging.getLogger('@('.'.join(message.structure.type.namespaces + [message.structure.type.name]))')
            logger.debug(
                'Failed to import needed modules for type support:\n' + traceback.format_exc())
        else:
@{
suffix = '__'.join(message.structure.type.namespaces[1:]) + '__' + convert_camel_case_to_lower_case_underscore(message.structure.type.name)
}@
            cls._CREATE_ROS_MESSAGE = module.create_ros_message_@(suffix)
            cls._CONVERT_FROM_PY = module.convert_from_py_@(suffix)
            cls._CONVERT_TO_PY = module.convert_to_py_@(suffix)
            cls._TYPE_SUPPORT = module.type_support_@(suffix)
            cls._DESTROY_ROS_MESSAGE = module.destroy_ros_message_@(suffix)
@{
importable_typesupports = set()
for member in message.structure.members:
    type_ = member.type
    if isinstance(type_, NestedType):
        type_ = type_.basetype
    if isinstance(type_, NamespacedType):
        typename = (*type_.namespaces, type_.name)
        importable_typesupports.add(typename)
}@
@[for typename in sorted(importable_typesupports)]@

            from @('.'.join(typename[:-1])) import @(typename[-1])
            if @(typename[-1]).__class__._TYPE_SUPPORT is None:
                @(typename[-1]).__class__.__import_type_support__()
@[end for]@

    @@classmethod
    def __prepare__(cls, name, bases, **kwargs):
        # list constant names here so that they appear in the help text of
        # the message class under "Data and other attributes defined here:"
        # as well as populate each message instance
        return {
@[for constant in message.constants.values()]@
            '@(constant.name)': cls.__constants['@(constant.name)'],
@[end for]@
@[for member in message.structure.members]@
@[  if member.has_annotation('default')]@
            '@(member.name.upper())__DEFAULT': @(value_to_py(member.type, member.get_annotation_value('default')['value'])),
@[  end if]@
@[end for]@
        }
@[for constant in message.constants.values()]@

    @@property
    def @(constant.name)(self):
        """Message constant '@(constant.name)'."""
        return Metaclass_@(message.structure.type.name).__constants['@(constant.name)']
@[end for]@
@[for member in message.structure.members]@
@[  if member.has_annotation('default')]@

    @@property
    def @(member.name.upper())__DEFAULT(cls):
        """Return default value for message field '@(member.name)'."""
        return @(value_to_py(member.type, member.get_annotation_value('default')['value']))
@[  end if]@
@[end for]@


class @(message.structure.type.name)(metaclass=Metaclass_@(message.structure.type.name)):
@[if not message.constants]@
    """Message class '@(message.structure.type.name)'."""
@[else]@
    """
    Message class '@(message.structure.type.name)'.

    Constants:
@[  for constant_name in message.constants.keys()]@
      @(constant_name)
@[  end for]@
    """
@[end if]@

    __slots__ = [
@[for member in message.structure.members]@
        '_@(member.name)',
@[end for]@
    ]

    _fields_and_field_types = {
@[for member in message.structure.members]@
@{
type_ = member.type
if isinstance(type_, NestedType):
    type_ = type_.basetype
}@
        '@(member.name)': '@
@# the prefix for nested types
@[  if isinstance(member.type, Sequence)]@
sequence<@
@[  end if]@
@# the typename of the non-nested type or the nested basetype
@[  if isinstance(type_, BasicType)]@
@(type_.type)@
@[  elif isinstance(type_, BaseString)]@
@
@[    if isinstance(type_, WString)]@
w@
@[    end if]@
string@
@[    if type_.maximum_size is not None]@
<@(type_.maximum_size)>@
@[    end if]@
@[  elif isinstance(type_, NamespacedType)]@
@('::'.join(type_.namespaces + [type_.name]))@
@[  end if]@
@# the suffix for nested types
@[  if isinstance(member.type, Sequence)]@
@[    if isinstance(member.type, BoundedSequence)]@
, @(member.type.upper_bound)@
@[    end if]@
>@
@[  elif isinstance(member.type, Array)]@
[@(member.type.size)]@
@[  end if]@
',
@[end for]@
    }

    def __init__(self, **kwargs):
        assert all('_' + key in self.__slots__ for key in kwargs.keys()), \
            'Invalid arguments passed to constructor: %s' % \
            ', '.join(sorted(k for k in kwargs.keys() if '_' + k not in self.__slots__))
@[for member in message.structure.members]@
@{
type_ = member.type
if isinstance(type_, NestedType):
    type_ = type_.basetype
}@
@[  if member.has_annotation('default')]@
        self.@(member.name) = kwargs.get(
            '@(member.name)', @(message.structure.type.name).@(member.name.upper())__DEFAULT)
@[  else]@
@[    if isinstance(type_, NamespacedType) and not isinstance(member.type, Sequence)]@
@#        import @('.'.join(type_.namespaces + [type_.name]))
        from @('.'.join(type_.namespaces)) import @(type_.name)
@[    end if]@
@[    if isinstance(member.type, Array)]@
@[      if isinstance(type_, BasicType) and type_.type == 'octet']@
        self.@(member.name) = kwargs.get(
            '@(member.name)',
            [bytes([0]) for x in range(@(member.type.size))]
        )
@[      elif isinstance(type_, BasicType) and type_.type in ('char', 'wchar')]@
        self.@(member.name) = kwargs.get(
            '@(member.name)',
            [chr(0) for x in range(@(member.type.size))]
        )
@[      else]@
        self.@(member.name) = kwargs.get(
            '@(member.name)',
            [@(get_python_type(type_))() for x in range(@(member.type.size))]
        )
@[      end if]@
@[    elif isinstance(member.type, Sequence)]@
        self.@(member.name) = kwargs.get('@(member.name)', [])
@[    elif isinstance(type_, BasicType) and type_.type == 'octet']@
        self.@(member.name) = kwargs.get('@(member.name)', bytes([0]))
@[    elif isinstance(type_, BasicType) and type_.type in ('char', 'wchar')]@
        self.@(member.name) = kwargs.get('@(member.name)', chr(0))
@[    else]@
        self.@(member.name) = kwargs.get('@(member.name)', @(get_python_type(type_))())
@[    end if]@
@[  end if]@
@[end for]@

    def __repr__(self):
        typename = self.__class__.__module__.split('.')
        typename.pop()
        typename.append(self.__class__.__name__)
        args = [s[1:] + '=' + repr(getattr(self, s, None)) for s in self.__slots__]
        return '%s(%s)' % ('.'.join(typename), ', '.join(args))

    def __eq__(self, other):
        if not isinstance(other, self.__class__):
            return False
@[for member in message.structure.members]@
        if self.@(member.name) != other.@(member.name):
            return False
@[end for]@
        return True

    @@classmethod
    def get_fields_and_field_types(cls):
        from copy import copy
        return copy(cls._fields_and_field_types)
@[for member in message.structure.members]@

@{
type_ = member.type
if isinstance(type_, NestedType):
    type_ = type_.basetype

import inspect
import builtins
noqa_string = ''
if member.name in dict(inspect.getmembers(builtins)).keys():
    noqa_string = '  # noqa: A003'
}@
    @@property@(noqa_string)
    def @(member.name)(self):
        """Message field '@(member.name)'."""
        return self._@(member.name)

    @@@(member.name).setter@(noqa_string)
    def @(member.name)(self, value):
        if __debug__:
@[  if isinstance(type_, NamespacedType)]@
@#            import @('.'.join(type_.namespaces + [type_.name]))
            from @('.'.join(type_.namespaces)) import @(type_.name)
@[  end if]@
@[  if isinstance(member.type, NestedType)]@
            from collections.abc import Sequence
            from collections.abc import Set
            from collections import UserList
            from collections import UserString
@[  elif isinstance(type_, String) and type_.maximum_size is not None]@
            from collections import UserString
@[  elif isinstance(type_, BasicType) and type_.type == 'octet']@
            from collections.abc import ByteString
@[  elif isinstance(type_, BasicType) and type_.type in ('char', 'wchar')]@
            from collections import UserString
@[  end if]@
            assert \
@[  if isinstance(member.type, NestedType)]@
                ((isinstance(value, Sequence) or
                  isinstance(value, Set) or
                  isinstance(value, UserList)) and
                 not isinstance(value, str) and
                 not isinstance(value, UserString) and
@{assert_msg_suffixes = ['a set or sequence']}@
@[    if isinstance(type_, String) and type_.maximum_size is not None]@
                 all(len(val) <= @(type_.maximum_size) for val in value) and
@{assert_msg_suffixes.append('and each string value not longer than %d' % type_.maximum_size)}@
@[    end if]@
@[    if isinstance(member.type, Array) or isinstance(member.type, BoundedSequence)]@
@[      if isinstance(member.type, BoundedSequence)]@
                 len(value) <= @(member.type.upper_bound) and
@{assert_msg_suffixes.insert(1, 'with length <= %d' % member.type.upper_bound)}@
@[      else]@
                 len(value) == @(member.type.size) and
@{assert_msg_suffixes.insert(1, 'with length %d' % member.type.size)}@
@[      end if]@
@[    end if]@
                 all(isinstance(v, @(get_python_type(type_))) for v in value) and
@{assert_msg_suffixes.append("and each value of type '%s'" % get_python_type(type_))}@
@[    if isinstance(type_, BasicType) and type_.type.startswith('int')]@
@{
nbits = int(type_.type[3:])
bound = 2**(nbits - 1)
}@
                 all(val >= -@(bound) and val < @(bound) for val in value)), \
@{assert_msg_suffixes.append('and each integer in [%d, %d]' % (-bound, bound - 1))}@
@[    elif isinstance(type_, BasicType) and type_.type.startswith('uint')]@
@{
nbits = int(type_.type[4:])
bound = 2**nbits
}@
                 all(val >= 0 and val < @(bound) for val in value)), \
@{assert_msg_suffixes.append('and each unsigned integer in [0, %d]' % (bound - 1))}@
@[    elif isinstance(type_, BasicType) and type_.type == 'char']@
                 all(ord(val) >= -128 and ord(val) < 128 for val in value)), \
@{assert_msg_suffixes.append('and each characters ord() in [-128, 127]')}@
@[    else]@
                 True), \
@[    end if]@
                "The '@(member.name)' field must be @(' '.join(assert_msg_suffixes))"
@[  elif isinstance(member.type, BaseString) and member.type.maximum_size is not None]@
                ((isinstance(value, str) or isinstance(value, UserString)) and
                 len(value) <= @(member.type.maximum_size)), \
                "The '@(member.name)' field must be string value " \
                'not longer than @(type_.maximum_size)'
@[  elif isinstance(type_, NamespacedType)]@
                isinstance(value, @(type_.name)), \
                "The '@(member.name)' field must be a sub message of type '@(type_.name)'"
@[  elif isinstance(type_, BasicType) and type_.type == 'octet']@
                ((isinstance(value, bytes) or isinstance(value, ByteString)) and
                 len(value) == 1), \
                "The '@(member.name)' field must of type 'bytes' or 'ByteString' with a length 1"
@[  elif isinstance(type_, BasicType) and type_.type == 'char']@
                ((isinstance(value, str) or isinstance(value, UserString)) and
                 len(value) == 1 and ord(value) >= -128 and ord(value) < 128), \
                "The '@(member.name)' field must of type 'str' or 'UserString' " \
                'with a length 1 and the character ord() in [-128, 127]'
@[  elif isinstance(type_, BaseString)]@
                isinstance(value, str), \
                "The '@(member.name)' field must of type '@(get_python_type(type_))'"
@[  elif isinstance(type_, BasicType) and type_.type in [
        'boolean',
        'float', 'double',
        'int8', 'uint8',
        'int16', 'uint16',
        'int32', 'uint32',
        'int64', 'uint64',
    ]]@
                isinstance(value, @(get_python_type(type_))), \
                "The '@(member.name)' field must of type '@(get_python_type(type_))'"
@[    if type_.type.startswith('int')]@
@{
nbits = int(type_.type[3:])
bound = 2**(nbits - 1)
}@
            assert value >= -@(bound) and value < @(bound), \
                "The '@(member.name)' field must be an integer in [@(-bound), @(bound - 1)]"
@[    elif type_.type.startswith('uint')]@
@{
nbits = int(type_.type[4:])
bound = 2**nbits
}@
            assert value >= 0 and value < @(bound), \
                "The '@(member.name)' field must be an unsigned integer in [0, @(bound - 1)]"
@[    end if]@
@[  else]@
                False
@[  end if]@
        self._@(member.name) = value
@[end for]@
